# Who needs sudo?
function Invoke-AsAdmin {
   param([string]$Command)

   Start-Process powershell -Verb RunAs -Wait -ArgumentList "-Command '& {$Command}'"
}

# Lower execution policy
Invoke-AsAdmin -Command "Set-ExecutionPolicy -Force Unrestricted"

# Software
## Metro apps
Write-Output "Removing all possible Metro apps"
Invoke-AsAdmin -Command "Get-AppXPackage -User | Remove-AppXPackage"
Invoke-AsAdmin -Command "Get-AppXPackage -AllUsers | Remove-AppXPackage"
## Packages
Write-Output "Installing Chocolatey package manager"
Invoke-AsAdmin -Command "Invoke-WebRequest https://chocolatey.org/install.ps1 | Invoke-Expression"
Write-Output "Installing packages"
Invoke-AsAdmin -Command "choco install -y googlechrome libreoffice visualstudiocode git github golang nodejs heroku-cli 7zip"

$ListsURL = "https://raw.githubusercontent.com/feskyde/things/master/lists"

function GitClone-FromRemoteList {
    param([string]$Uri)
    Invoke-WebRequest -Uri $Uri -OutFile list.txt
    Get-Content list.txt | ForEach-Object {
        git clone --recursive $_
    }
}

function GoGet-FromRemoteList {
    param([string]$Uri)
    Invoke-WebRequest -Uri $Uri -OutFile list.txt
    Get-Content list.txt | ForEach-Object {
        go get -v -u $_
    }
}

# Get Git repositories
GitClone-FromRemoteList -Uri "$ListsURL/common/git_repositories.txt"

# Get Go packages
GoGet-FromRemoteList -Uri "$ListsURL/common/go_packages.txt"
