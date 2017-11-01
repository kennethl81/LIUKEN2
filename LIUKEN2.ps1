$global:email = "" #reference to email
$global:password = "" #reference to password
$global:saveLocation = "C:\GoodReads_Mark_Twain_Quotes_$(Get-Date -f yyyy-mm-dd-hh-ss-ms).txt"
$global:quotesToGet = 10 #limits the number of quotes to retrieve
$global:JSONEscaped = $false #set to $true to keep JSON escaped, $false to unescape
$global:IEVisible = $false #set to $true if you would like the IE browser to physically open, set to $false to run in the background
$global:testMode = $false #set to $true to use default login information, set to $false to prompt user to input login information

<#IMPORTANT#>
#Please run this script with administrative control of PowerShell or PowerShell ISE
#If script execution is blocked, use this command to enable it: Set-ExecutionPolicy RemoteSigned


#starts the workflow of the script
function StartScript()
{

    Write-Host 'Please run this script with administrative control of PowerShell or PowerShell ISE'

    Write-Host 'To login, this script will prompt you for email and password to goodreads.com'
    doInputPrompt

   $ieObject = New-Object -com InternetExplorer.Application
   $check = DoWebAuthentication($ieObject)
    Do
    {
        if($ieObject.LocationURL -ne 'https://www.goodreads.com/') { #if we can reach the homepage after calling the authentication function, then it means we are authenticated
            Write-Output "Authentication failed. Please try again."
            doInputPrompt
            $check = DoWebAuthentication($ieObject)
        }

    }
    Until($true -eq $check)


    $data =  LookForMarkTwainQuotes($ieObject)

    if($data -ne $null)
    {
        $dataConvertToJSON = ConvertDataToJSON($data)
        
        if($dataConvertToJSON)
        {
            WriteFileToDirectory $dataConvertToJSON $global:saveLocation

            DoSignOut($ieObject)
            CloseIEBrowserProcess($ieObject)
            Write-Output "Execution complete!"
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
function DoWebAuthentication($ie)
{
    if($ie -ne $null) 
    {
        Write-Host 'Attempting to Authenticate...'
        Write-Host 'Opening IE Process'

        $ie.visible=$global:IEVisible

        if(CheckConnection "https://www.goodreads.com/") 
        {
            $ie.navigate("https://www.goodreads.com/")
            WaitForPageToLoad($ie)

            #check to see if the user is already signed in, if the user is signed in, there shouldn't be a "Sign in" button
            $checkForSignInButton = $ie.document.getElementsByTagName("form") | ? {$_.id -eq 'sign_in'}

            if($checkForSignInButton -eq $null) {

                Write-Host 'There was a previous session still logged on. Triggering sign out of other account so we can log in with the newer supplied credentials'
                DoSignOut($ie)  
            }

                    $ie.navigate("https://www.goodreads.com/user/sign_in") 
                    WaitForPageToLoad($ie)

                    $ie.document.getElementById("user_email").value = $global:email 
                    $ie.document.getElementById("user_password").value = $global:password 
                    $ie.document.getElementsByName("sign_in")
                    $submit = $ie.document.getElementsByTagName("input") | ? { $_.name -eq "next"} #this is the submit button

                    if($submit)
                    {
                        $submit.click()

    
                            Start-Sleep -seconds 4 #from testing, we need an ample amount of time for loading the page after sign-in

                             $checkSignInButton = $ie.document.getElementsByTagName("input") | ? { $_.name -eq "next"} #this is the submit button

                            if($checkSignInButton -ne $null)
                            {
                                return $false
                            } 
                            else 
                            {
                                Write-Host 'Authenticated'
                                #once authenticated, return $ie to be used in other functions
                                return $true
                            }
                        }
            }
        }
    return $false
}

#closes the IE Browser process
#pre-condition: $ie is not null
function CloseIEBrowserProcess($ie) 
{
    Write-Host 'Closing background IE process'

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
        $timeToWait = 1; #this sets the time to wait between checks for ReadyState (in seconds)
        $exit = $false

        Do
        {
            if($ie.ReadyState -eq 4)
            {
                $exit = $true
            } 

            Start-Sleep -seconds $timeToWait

        }
        Until($exit)
    }
}

function DoSignOut($ie)
{
    if($ie -ne $null)
    {
        if(CheckConnection "https://www.goodreads.com/user/sign_out")
        {
            $ie.navigate("https://www.goodreads.com/user/sign_out")
            WaitForPageToLoad($ie)

            $signOutContainer = $ie.document.getElementsByClassName("intro") | %{
                
                $signOutLink = $_.getElementsByTagName("a")| ? { $_.innerText -Match "click here."}

                if($signOutLink -ne $null)
                {
                    $signOutLink.click()
                    WaitForPageToLoad($ie)

                    $ie.navigate("https://www.goodreads.com")
                    WaitForPageToLoad($ie)
                }
            }
        }
    }
}

#scrapes data from the goodreads.com quotes page. Returns a hashtable with key=quote order value=quote text
#pre-condition: $ie is not null
function LookForMarkTwainQuotes($ie) 
{
    if($ie -ne $null)
    {
        Write-Host "Retrieving data please wait..."

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

            Write-Host 'Data Retrieved:' ($data | Out-String)

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

    Write-Host 'Writing data...'

    if($data -ne $null -and $global:JSONEscaped) 
    {
        $data | Out-File $fileNameAndPath
    } 
    else 
    {
        $data |  %{ [System.Text.RegularExpressions.Regex]::Unescape($_) } | Out-File $fileNameAndPath
    }

    Write-Output "File saved as: $global:saveLocation"
}

#converts data in JSON format, returns $null if $data is null
#pre-condition: $data is not null
function ConvertDataToJSON($data) 
{
    Write-Host 'Converting data to JSON for output'

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