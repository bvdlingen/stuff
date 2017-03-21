# Allow current user to execute scripts
Write-Output "Setting execution policy to Unrestricted"
Set-ExecutionPolicy -Force Unrestricted

# Software
## Metro apps
### Remove unused apps
Write-Output "Removing unused Metro apps"
Get-AppXPackage -AllUsers -Name *zune* | Remove-AppXPackage
Get-AppXPackage -AllUsers -Name *bing* | Remove-AppXPackage
Get-AppXPackage -AllUsers -Name *xbox* | Remove-AppXPackage
Get-AppXPackage -AllUsers -Name *office* | Remove-AppXPackage
Get-AppXPackage -AllUsers -Name *skype* | Remove-AppXPackage
## Packages
### Enable the Chocolatey provider
Write-Output "Enabling Chocolatey provider"
Get-PackageProvider -Name Chocolatey
### Install packages from Chocolatey
Write-Output "Installing packages"
Install-Package -Name "googlechrome","libreoffice","visualstudiocode","git","github","golang","nodejs","7zip" -ProviderName Chocolatey
