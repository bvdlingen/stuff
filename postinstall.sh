#!/usr/bin/env bash
#
# Solus Post Install Script
#

# Lists (bad design is bad)
LISTS_RAW_URL="https://raw.githubusercontent.com/feskyde/solus-stuff/master/lists"
# Third Party specs
SPECS_RAW_URL="https://raw.githubusercontent.com/solus-project/3rd-party/master"

# Functions
function new_step_notify() {
    message="$1"

    printf "\e[1m>> %s\e[0m\n" "$message"
    notify-send "Solus Post Install" "$message" -i distributor-logo-solus
}

function checkout_folder() {
    folder="$1"

    if [ ! -d "$folder" ]; then
        mkdir -pv "$folder"
    fi
    printf "\e[1m  - Now in folder: %s\e[0m\n" "$folder"
    cd "$folder" || exit
}

function third_party_install_from_list() {
    third_list="$1"

    wget "$third_list" -O list_tpkg.txt
    while ISC='' read -r tpkg_dir || [ -n "$tpkg_dir" ]; do
        printf "\e[1m  - Installing third-party package: %s\e[0m\n" "$tpkg_dir"
        sudo eopkg build -y --ignore-safety "$SPECS_RAW_URL"/"$tpkg_dir"/pspec.xml
        sudo eopkg install -y ./*.eopkg
        rm -rfv ./*.eopkg
    done < list_tpkg.txt
    rm -rfv list_tpkg.txt
}

function clone_repositories_from_list() {
    repo_list="$1"

    wget "$repo_list" -O list_clone.txt
    while ISC='' read -r git_repo || [ -n "$git_repo" ]; do
        printf "\e[1m  - Clonning repository: %s\e[0m\n" "$git_repo"
        git clone --recursive "$git_repo"
    done < list_clone.txt
    rm -rfv list_clone.txt
}

function go_get_packages_from_list() {
    pkgs_list="$1"

    wget "$pkgs_list" -O list_go_get.txt
    while ISC='' read -r gpkg_path || [ -n "$gpkg_path" ]; do
        printf "\e[1m  - Installing Go package: %s\e[0m\n" "$gpkg_path"
        go get -v -u "$gpkg_path"
    done < list_go_get.txt
    rm -rfv list_go_get.txt
}

# Welcome
new_step_notify "Script is now running, do not touch anything until it finishes :)"

# Password-less user
new_step_notify "Setting password-less user (EXTREMELY INSANE STUFF)"
## Remove password for Casa
sudo passwd -du casa
## Add nullok option to PAM files
sudo find /etc/pam.d -name "*" -exec sed -i {} -e "s:try_first_pass nullok:try_first_pass:g" \
                                               -e "s:pam_unix.so:pam_unix.so nullok:g" \;

# Manage repositories
new_step_notify "Switching to Unstable repository"
## Remove Solus (Shannon)
sudo eopkg remove-repo -y Solus
## Add Unstable
sudo eopkg add-repo -y Solus https://packages.solus-project.com/unstable/eopkg-index.xml.xz

# Manage packages
## Upgrade the system
new_step_notify "Getting system up to date"
sudo eopkg upgrade -y
## Install third party stuff
new_step_notify "Installing third party packages"
third_party_install_from_list "$LISTS_RAW_URL/third_party.txt"
## Install extra applications and stuff
new_step_notify "Installing more packages"
sudo eopkg install -y caja-extensions simplescreenrecorder libreoffice-all zsh git{,-extras} yadm golang solbuild{,-config-unstable}

# Development packages and Solbuild
## Install development component
new_step_notify "Installing development component"
sudo eopkg install -y -c system.devel
## Set up solbuild
new_step_notify "Setting up solbuild"
sudo solbuild init -u

# Dotfiles
new_step_notify "Setting-up dotfiles"
## Clone the repository and decrypt the binary
yadm clone -f https://github.com/feskyde/dotfiles
yadm decrypt
## Default to ZSH
sudo chsh -s /bin/zsh casa

# Git repositories
new_step_notify "Cloning repositories"
checkout_folder ~/Git
## GitHub repositories
clone_repositories_from_list "$LISTS_RAW_URL/github_repos.txt"
## Return to home
cd ~ || exit

# Solus packaging repository
## Create packages folder
new_step_notify "Setting up Solus packages folder"
checkout_folder ~/Git/packages
## Clone common repository
new_step_notify "Clonning common repository"
while true; do
    if [ ! -d common ]; then
        git clone --recursive https://git.solus-project.com/common
    else
        break
    fi
done
## Link makefiles
new_step_notify "Linking makefiles"
ln -srfv common/Makefile.common Makefile.common
ln -srfv common/Makefile.iso Makefile.iso
ln -srfv common/Makefile.toplevel Makefile
## Clone all source repositories
new_step_notify "Clonning all source repositories"
make clone
## Return to home
cd ~ || exit

# System configuration
new_step_notify "Installing system configuration files"
checkout_folder ~/Git/solus-stuff/config
bash ./bootstrap.sh
## Return to home
cd ~ || exit

# Telegram Desktop
new_step_notify "Installing Telegram Desktop"
## Enter into the Telegram folder
checkout_folder ~/.TelegramDesktop
## Download the tarball
wget https://tdesktop.com/linux/current?alpha=1 -O telegram-desktop.tar.xz
## Unpack it
tar xfv telegram-desktop.tar.xz --strip-components=1 --show-transformed-names
rm -rfv telegram-desktop.tar.xz
## Back to home
cd ~ || exit

# Package Control
new_step_notify "Installing package control"
## Enter to Sublime packages folder
checkout_folder ~/.config/sublime-text-3/Installed\ Packages
## Download the package
wget https://packagecontrol.io/Package%20Control.sublime-package -O Package\ Control.sublime-package
## Back to home
cd ~ || exit

# Go packages
new_step_notify "Installing Go packages"
## Fixes
### Export GOPATH so the Go packages installation will not go KABOOM!
export GOPATH=$HOME/.golang
## Install packages
go_get_packages_from_list "$LISTS_RAW_URL/go_packages.txt"

# FINISHED!
new_step_notify "Script has finished! You should reboot as soon as possible"
