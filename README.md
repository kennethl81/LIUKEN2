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

To run Pester unit tests, press CTRL + F5
