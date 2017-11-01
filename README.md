# LIUKEN2
Code Challenge #2

Installation
===================================================

This script is using the PowerShell Pester Unit testing framework. While not required to run this script. Installation instructions are below:

Use this link for a detailed setup guide for Pester unit test:
    https://writeabout.net/2016/01/14/run-pester-tests-in-powershell-ise-with-isepester/

Use this link on how to write IsePester unit tests:
    https://github.com/dfinke/IsePester

Open PowerShell ISE in administrator mode.

Run this command to install chocolatey:
    iex ((new-object net.webclient).DownloadString('https://chocolatey.org/install.ps1'))

Next install Pester (PowerShell Unit Testing Framework):
    choco Install Pester -y -f

Next install ISEPester:
    choco Install IsePester -y

Restart PowerShell ISE in administrator mode

The Tests developed through TDD:
-Try a connection to a URL
-Check to see if the user can access and write to a directory
-Check to see if we can validate an email address input by the user
-Check to see if we can convert data to JSON (for output)

How to Use
===================================================
!VERY IMPORTANT!

    Prior to running the script, ensure that Internet Explorer was initialized and used previously. 
    The script may be blocked by Internet Explorer running if it requires the user to specify
    their start up (first-use) settings.
    
    Also ensure that there is not a lot of Internet Explorer background processes running prior to 
    running the script. When there are too many background IE processes running, the script will
    complain that there is insufficient memory to run.
    
    The recommended way of running the script is through PowerShell ISE (run as administrator)
    
    If you are blocked from running scripts in your PowerShell ISE or PowerShell command window
    Use this command to allow running scripts on your system:
        Set-ExecutionPolicy RemoteSigned


Unit tests:

    Unit tests are run first automatically every time the script is executed.
    The unit test will display passing tests as green and failed tests as red.
    
Script:

    After executing the script, the script will prompt the user for an email and a 
    password to login to goodreads.com. 
    
    If a user does not input a valid email address the script will continue to prompt 
    the user until a valid email is entered. I chose to use a built in email validation 
    function from PowerShell to validate email address input.
