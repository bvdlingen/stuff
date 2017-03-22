Set-ExecutionPolicy -Force Unrestricted

function Remove-MetroApp {
    param([string]$Name)
    Get-AppXPackage -User -Name $Name | Remove-AppXPackage
    Get-AppXPackage -AllUsers -Name $Name | Remove-AppXPackage
}

# Software
## Metro apps
Write-Output "Removing unused Metro apps"
Remove-MetroApp -Name *3dbuilder*
Remove-MetroApp -Name *bing*
Remove-MetroApp -Name *office*
Remove-MetroApp -Name *skype*
Remove-MetroApp -Name *xbox*
Remove-MetroApp -Name *zune*
## Packages
Write-Output "Checking if the Chocolatey provider is enabled"
Get-PackageProvider -Name Chocolatey
Write-Output "Installing packages"
Find-Package -Name googlechrome,libreoffice,visualstudiocode,git,github,golang,nodejs,heroku-cli,7zip -ProviderName Chocolatey | Install-Package -Force
