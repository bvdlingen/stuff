#!/data/data/com.termux/files/usr/bin/env bash
#
# Termux Post Install Script
#

# Lists (bad design is bad)
LISTS_RAW_URL="https://raw.githubusercontent.com/feddasch/things/master/lists"

# Functions
function notify_step() {
    message="$1"

    echo -e ">> $message"
}

function checkout_folder() {
    folder="$1"

    if [ ! -d "$folder" ]; then
        mkdir -pv "$folder"
    fi
    echo -e "- Now in folder: $folder"
    cd "$folder" || exit
}

function clone_repositories_from_list() {
    repo_list="$1"

    wget "$repo_list" -O list_clone.txt
    while ISC='' read -r git_repo || [ -n "$git_repo" ]; do
        echo -e "- Clonning repository: $git_repo"
        git clone --recursive "$git_repo"
    done < list_clone.txt
    rm -rfv list_clone.txt
}

function go_get_from_list() {
    pkgs_list="$1"

    wget "$pkgs_list" -O list_go_get.txt
    while ISC='' read -r gpkg_path || [ -n "$gpkg_path" ]; do
        echo -e "- Installing Go package: $gpkg_path"
        go get -v -u "$gpkg_path"
    done < list_go_get.txt
    rm -rfv list_go_get.txt
}

# Welcome
notify_step "Script is now running, do not touch anything until it finishes :)"

# Manage packages
## Upgrade the system
notify_step "Getting system up to date"
packages upgrade
## Install extra applications and stuff
notify_step "Installing more packages"
packages install fish neofetch git gnupg golang neovim {python{,-2},nodejs}-dev make
for py in 2 3; do
    pip$py install neovim
done

# Dotfiles
notify_step "Setting-up dotfiles"
## Get YADM
git clone https://github.com/TheLocehiliosan/yadm
## Fix shebang
termux-fix-shebang yadm/yadm
## Clone the repository and decrypt the binary
yadm/yadm clone -f https://github.com/feddasch/dotfiles
yadm/yadm decrypt

# Git repositories
notify_step "Cloning repositories"
checkout_folder "$HOME/Projectos"
## GitHub repositories
clone_repositories_from_list "$LISTS_RAW_URL/common/git_repos.txt"
## Return to home
cd || exit

# Go packages
notify_step "Installing Go packages"
## Fixes
### Create GOPATH so the Go packages installation will not go KABOOM!
export GOPATH="$HOME/.golang"
checkout_folder "$GOPATH"
cd || exit
## Install packages
go_get_from_list "$LISTS_RAW_URL/common/go_packages.txt"
