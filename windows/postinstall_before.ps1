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
