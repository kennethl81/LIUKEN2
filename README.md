# LIUKEN2
Code Challenge #2

===================================================
Installation

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
===================================================
The Tests developed through TDD:
-Try a connection to a URL
-Check to see if the user can access and write to a directory
-Check to see if we can validate an email address input by the user
-Check to see if we can convert data to JSON (for output)
===================================================
How to use:

Unit tests:
    Unit tests are run first automatically every time the script is executed.
    The unit test will display passing tests as green and failed tests as red.
    
Script:
    After executing the script, the script will prompt the user for an email and a password to login to goodreads.com. If a user does not input a valid email address
    the script will continue to prompt the user until a valid email is entered.