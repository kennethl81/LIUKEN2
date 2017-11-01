$global:email = "" #reference to email
$global:password = "" #reference to password
$global:saveLocation = "C:\GoodReads_Mark_Twain_Quotes_$(Get-Date -f yyyy-mm-dd-hh-ss-ms).txt"
$global:quotesToGet = 10 #limits the number of quotes to retrieve
$global:JSONEscaped = $false #set to $true to keep JSON escaped, $false to unescape
$global:IEVisible = $false #set to $true if you would like the IE browser to physically open, set to $false to run in the background
$global:testMode = $false #set to $true to use default login information, set to $false to prompt user to input login information

#starts the workflow of the script
function StartScript()
{
    Write-Output 'To login, this script will prompt you for email and password to goodreads.com'
    doInputPrompt

    $ieObject = DoWebAuthentication

    if($ieObject -eq $null) 
    {
        doInputPrompt
        $ieObject = DoWebAuthentication
    } 
    else 
    {
       Write-Output "Retrieving data..."
       $data =  LookForMarkTwainQuotes($ieObject)

       if($data -ne $null)
       {
            $dataConvertToJSON = ConvertDataToJSON($data)
        
            if($dataConvertToJSON)
            {
                Write-Output "Writing file to: $global:saveLocation"
                WriteFileToDirectory $dataConvertToJSON $global:saveLocation

                CloseIEBrowserProcess($ieObject)
                Write-Output "Execution complete!"
            }
       }
    }
}

#prompts the user for email and password. Continues to prompt until valid format is supplied by the user
function doInputPrompt() {

    if($global:testMode) {

        $global:email = "kennethl81@gmail.com"
        $global:password = "expedia"

    } else {
        $global:email = Read-Host -Prompt 'Enter your email'

        $validateEmail = CheckEmailAddress($global:email)

        if($validateEmail)
        {
            $global:password  = Read-Host -Prompt 'Enter your password'

        } 
        else 
        {
            Write-Output "Email address is in an incorrect format, please try again"
            doInputPrompt
        }
    }
}

#does an authentication to the goodreads.com website. Returns an Internet Explorer object.
function DoWebAuthentication()
{
    $ie = New-Object -com InternetExplorer.Application

    if($ie -ne $null) 
    { 

        $ie.visible=$global:IEVisible

        if(CheckConnection "https://www.goodreads.com") 
        {
            $ie.navigate("https://www.goodreads.com")
            WaitForPageToLoad($ie)

            #check to see if the user is already signed in, if the user is signed in, there shouldn't be a "Sign in" button
            $checkForSignInButton = $ie.document.getElementsByTagName("form") | ? {$_.id -eq 'sign_in'}

            if($checkForSignInButton -ne $null) #if there is not a sign in button, then the user is currently signed in already (maybe with another account). Force a sign out
            {
                if(CheckConnection "https://www.goodreads.com/user/sign_in") 
                {
                    $ie.navigate("https://www.goodreads.com/user/sign_in") 
                    WaitForPageToLoad($ie)

                    $ie.document.getElementById("user_email").value = $global:email 
                    $ie.document.getElementById("user_password").value = $global:password 
                    $ie.document.getElementsByName("sign_in")
                    $submit = $ie.document.getElementsByTagName("input") | ? { $_.name -eq "next"} #this is the submit button

                    if($submit)
                    {
                        $submit.click()
                    }
                }
            }

            WaitForPageToLoad($ie)
            $checkIfSignInError = $ie.document.getElementsByClassName("flash error")

            if($checkIfSignInError -ne $null) 
            {
                Write-Output $checkIfSignInError | SELECT InnerHTML
                return $null
            } 
            else 
            {
                #once authenticated, return $ie to be used in other functions
                return $ie
            }
        }
    }
    return $null
}

#closes the IE Browser process
#pre-condition: $ie is not null
function CloseIEBrowserProcess($ie) 
{
    if($ie -ne $null) 
    {
        $ie.Quit()
    }
}

#used to block until pages finished loading
#pre-condition: $ie is not null
function WaitForPageToLoad($ie)
{
    if($ie -ne $null) 
    {
        $timeToWait = 500; #this sets the time to wait between checks for ReadyState (in milliseconds)
        $count = 0;
        while($ie.ReadyState -ne 4) 
        {

            if($count -eq ($timeToWait * 10)) #if we try 10 times to load the page and it fails, we exit here
            {
                Write-Output "There was a problem accessing a page on goodreads.com. Please try again later."
                Write-Output "==Exiting script=="
                exit
            }

            Start-Sleep -Milliseconds $timeToWait #sleep so we can wait for the page to load and recheck

            $count++
        }
    }
}

#scrapes data from the goodreads.com quotes page. Returns a hashtable with key=quote order value=quote text
#pre-condition: $ie is not null
function LookForMarkTwainQuotes($ie) 
{
    if($ie -ne $null)
    {
        if(CheckConnection "https://www.goodreads.com/search?q=mark+twain&search%5Bsource%5D=goodreads&search_type=quotes&tab=quotes")
        {
            $ie.navigate("https://www.goodreads.com/search?q=mark+twain&search%5Bsource%5D=goodreads&search_type=quotes&tab=quotes") #does a redirect to the quotes page
            WaitForPageToLoad($ie)

            #scrape data
            $data = @{}
            $count = 1;

            $test = $ie.document.getElementsByTagName("div") | ? classname -eq "quoteText" | %{
            
                $check = $_.getElementsByTagName("a") | ?{ $_.title -eq 'Mark Twain quotes' }

                if($check) 
                { #if $check has a value it means we have a Mark Twain quote
                
                    $getQuoteText = $_ | SELECT innerText

                    if($count -ile $global:quotesToGet) 
                    {
                        $data.Add($count.ToString(), ($getQuoteText.innerText -replace '\"', "'").Trim()) #replace double quotes with single quotes for better JSON formatting
                    } 

                    $count++
                }
            }

            #sort results
            $data = $data.GetEnumerator() | Sort-Object -Property { [int]$_.key }
            return $data
        }
        
    }

    return $null
}

#validates whether an email is in a valid format. Returns $false if $data is null or email is invalid
#pre-condition: $data is not null
function CheckEmailAddress([string]$data)
{
   if($data -ne $null) 
   {
        return ($data -as [System.Net.Mail.MailAddress]).Address -eq $data
   } 
   else 
   {
        return $false
   }
}

#checks to see if a URL is reachable
#$pre-condition: data assumes that the URL is in a valid format
function CheckConnection([string]$data) 
{
    if($data -ne $null)
    {
        $HTTP_Request = [System.Net.WebRequest]::Create($data)

        $HTTP_Response = $HTTP_Request.GetResponse()

        $HTTP_Status = [int]$HTTP_Response.StatusCode

        return $HTTP_Status -eq 200
    } 
    else 
    {
        return $false
    }
}

#writes a file to a specified directory. If $fileNameAndPath is not valid, an error is thrown
#pre-condition: $data is not null
function WriteFileToDirectory($data, $fileNameAndPath)
{
    if($data -ne $null -and $global:JSONEscaped) 
    {
        $data | Out-File $fileNameAndPath
    } 
    else 
    {
        $data |  %{ [System.Text.RegularExpressions.Regex]::Unescape($_) } | Out-File $fileNameAndPath
    }
}

#converts data in JSON format, returns $null if $data is null
#pre-condition: $data is not null
function ConvertDataToJSON($data) 
{
    if($data -ne $null)
    {
        return $data | ConvertTo-JSON
    } 
    else
    {
        return $null
    }
}

#tests the ability of the script to reach out to a website url
Describe 'Try Connection For Sign In'{

    $HTTP_Status = CheckConnection "https://www.goodreads.com/user/sign_in"

    It 'testing TryConnection' { 
        $HTTP_Status | should be $true
    }
}

#tests the ability of the script to access the file system
Describe 'Can Write to Directory' {
    
    $data = "this is a test"
    $fileNameAndPath = "C:\\LIUKEN2_Test.txt"
    WriteFileToDirectory $data $fileNameAndPath

    $testPath = Test-Path -Path $fileNameAndPath

    It 'testing Can Write to Directory' {
        $testPath | should be $true
    }

    #clean-up: delete file after validation
    Remove-Item $fileNameAndPath
}

#testing the validation behavior of the script
Describe 'Check for Valid Email Address' {
   
    $check = CheckEmailAddress('test@example.com')

    It 'testing Email Address' {
        $check | should be $true
    }
}

#test ability to transform data into JSON format for output
Describe 'Check for Data Conversion to JSON' {
    $data = @{}

    for($i = 0; $i -lt 10; $i++)
    {
        $data.Add($i.toString(), "This is entry #" + $i)
    }

    $ConvertToJSON = $data | ConvertTo-Json

    $ConverToJSONUsingFunction = ConvertDataToJSON($data)

    It 'Comparing if data was converted to JSON'{
        $ConvertToJSON | should be $ConverToJSONUsingFunction
    }
}

#call functions here
StartScript