#!/usr/bin/env bash
#
# Solus Post Install Script
#

# Lists (bad design is bad)
LISTS_RAW_URL="https://raw.githubusercontent.com/feskyde/solus-stuff/master/lists"

# Functions
function print_step() {
    # Usage: print_step [message]
    # Print a styled [message]
    message="$1"

    printf "\e[1m>> %s\e[0m\n" "$message"
    notify-send "Solus Post Install" "$message" -i distributor-logo-solus
}

function folder_enter() {
    # Usage: folder_enter [folder]
    # Enter into a [folder], if it does not
    # exists, just create it
    folder="$1"

    if [ ! -d "$folder" ]; then
        mkdir -pv "$folder"
    fi
    cd "$folder" || exit
}

# Usage: repo_clone [url]
alias repo_clone="hub clone --recursive"

function tpkg_from_list() {
    # Usage: tpkg_from_list [list]
    # Build and install third party packages
    # from the given [list]
    list="$1"

    wget "$list" -O list.txt
    while ISC='' read -r tpkg_dir || [ -n "$tpkg_dir" ]; do
        sudo eopkg build -y --ignore-safety https://raw.githubusercontent.com/solus-project/3rd-party/master/"$tpkg_dir"/pspec.xml
        sudo eopkg install -y ./*.eopkg
        rm -rfv ./*.eopkg
    done < list.txt
    rm -rfv list.txt
}

function clone_from_list() {
    # Usage: clone_from_list [url] [list]
    # Clone every item on [list] file using the
    # Git repositories from [url] as main URL
    list="$1"

    wget "$list" -O list.txt
    while ISC='' read -r git_repo || [ -n "$git_repo" ]; do
        repo_clone "$git_repo"
    done < list.txt
    rm -rfv list.txt
}

function go_get_from_list() {
    # Usage: go_get_from_list [list]
    # Get every package listed in the file [list]
    list="$1"

    wget "$list" -O list.txt
    while ISC='' read -r gpkg_path || [ -n "$gpkg_path" ]; do
        go get -v -u "$gpkg_path"
    done < list.txt
    rm -rfv list.txt
}

# Welcome
print_step "Script is now running, do not touch anything until it finishes :)"

# Password-less user
## Remove password for Casa
print_step "Setting password-less user"
sudo passwd -du "$(whoami)"
## Add nullok option to PAM files
print_step "Adding nullok option to PAM files (EXTREMELY INSANE STUFF)"
sudo sed -e "s/sha512 shadow try_first_pass nullok/sha512 shadow try_first_pass/g" -i /etc/pam.d/system-password
sudo sed -e "s/pam_unix.so/pam_unix.so nullok/g" -i /etc/pam.d/*

# Manage repositories
## Remove Solus (Shannon)
print_step "Removing repository Solus"
sudo eopkg remove-repo -y Solus
## Add Unstable
print_step "Adding Unstable repository"
sudo eopkg add-repo -y Solus https://packages.solus-project.com/unstable/eopkg-index.xml.xz

# Manage packages
## Upgrade the system
print_step "Getting system up to date"
sudo eopkg upgrade -y
## Install extra applications and stuff
print_step "Installing more packages"
sudo eopkg install -y galculator gimp inkscape obs-studio kodi libreoffice-all lutris zsh git{,-extras} hub yadm {python-,}neovim hugo golang yarn neofetch solbuild{,-config-unstable} cve-check-tool
## Install third party stuff
print_step "Installing third party packages"
tpkg_from_list "$LISTS_RAW_URL/third_party.txt"

# Development packages and Solbuild
## Install development component
print_step "Installing development component"
sudo eopkg install -y -c system.devel
## Set up solbuild
print_step "Setting up solbuild"
sudo solbuild init -u

# Dotfiles
print_step "Setting-up dotfiles"
yadm clone https://github.com/feskyde/dotfiles
yadm decrypt
## Default to ZSH
print_step "Setting default shell"
chsh -s /bin/zsh "$(whoami)"

# Git repositories
folder_enter ~/Git
## GitHub repositories
print_step "Cloning GitHub repositories"
clone_from_list "$LISTS_RAW_URL/github_repos.txt"
## Extra repositories
print_step "Cloning extra repositories"
clone_from_list "$LISTS_RAW_URL/extra_repos.txt"
## Return to home
cd ~ || exit

# Solus packaging repository
## Create packages folder
print_step "Setting up Solus packages folder"
folder_enter ~/Git/packages
## Clone common repository
repo_clone https://git.solus-project.com/common
## Link makefiles
print_step "Linking makefiles"
ln -srfv common/Makefile.common Makefile.common
ln -srfv common/Makefile.iso Makefile.iso
ln -srfv common/Makefile.toplevel Makefile
## Clone package repositories
print_step "Cloning package repositories"
make clone
## Return to home
cd ~ || exit

# System configuration
print_step "Installing system configuration files"
folder_enter ~/Git/solus-stuff/config
bash bootstrap.sh
## Return to home
cd ~ || exit

# Telegram Desktop
print_step "Installing Telegram Desktop"
## Enter into the Telegram folder
folder_enter ~/.TelegramDesktop
## Download the tarball
wget https://tdesktop.com/linux/current?alpha=1 -O telegram-desktop.tar.xz
## Unpack it
tar xfv telegram-desktop.tar.xz --strip-components=1 --show-transformed-names
rm -rfv telegram-desktop.tar.xz
## Back to home
cd ~ || exit

# Deezloader App
print_step "Setting-up Deezloader App"
folder_enter ~/Git/deezloader-app
yarn install
## Back to home
cd ~ || exit

# Go packages
## Fixes
### Export GOPATH so the Go packages installation will not explode
export GOPATH=$(realpath ~/.golang)
## Install packages
print_step "Installing Go packages"
go_get_from_list "$LISTS_RAW_URL/go_packages.txt"

# FINISHED!
print_step "Script has finished! You should reboot as soon as possible"
