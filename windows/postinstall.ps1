# Functions
function Remove-MetroApps {
    param([string]$Regexp)

    Get-AppxPackage -AllUsers "*$Regexp*" | Remove-AppxPackage
}

# Lower execution policy
Set-ExecutionPolicy -Force RemoteSigned

# Packages
Write-Output "Installing packages"
## Install Chocolatey Package Manager
Invoke-WebRequest -UseBasicParsing https://chocolatey.org/install.ps1 | Invoke-Expression
## Refresh the environment
refreshenv
## Install packages... duh
choco install -y googlechrome libreoffice visualstudiocode git golang nodejs heroku-cli 7zip

# Metro apps
Write-Output "Removing metro apps"
## Remove all
Remove-MetroApps xbox
Remove-MetroApps bing
Remove-MetroApps zune
Remove-MetroApps paint
Remove-MetroApps 3d
Remove-MetroApps skype
Remove-MetroApps messaging
