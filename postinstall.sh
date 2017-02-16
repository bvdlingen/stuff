#!/usr/bin/env bash
#
# Solus Post Install Script
#

# Lists (bad design is bad)
LISTS_RAW_URL="https://raw.githubusercontent.com/feskyde/solus-stuff/master/lists"
# Third Party specs
SPECS_RAW_URL="https://raw.githubusercontent.com/solus-project/3rd-party/master"

# Functions
function print_step() {
    message="$1"

    printf "\e[1m>> %s\e[0m\n" "$message"
    notify-send "Solus Post Install" "$message" -i distributor-logo-solus
}

function enter_folder() {
    folder="$1"

    if [ ! -d "$folder" ]; then
        mkdir -pv "$folder"
    fi
    cd "$folder" || exit
}

function repo_clone() {
    repo="$1"

    git clone --recursive "$repo"
}

function tpkg_list() {
    third_list="$1"

    wget "$third_list" -O list.txt
    while ISC='' read -r tpkg_dir || [ -n "$tpkg_dir" ]; do
        sudo eopkg build -y --ignore-safety "$SPECS_RAW_URL"/"$tpkg_dir"/pspec.xml
        sudo eopkg install -y ./*.eopkg
        rm -rfv ./*.eopkg
    done < list.txt
    rm -rfv list.txt
}

function clone_list() {
    repo_list="$1"
    repo_url="$2"

    wget "$repo_list" -O list.txt
    while ISC='' read -r git_repo || [ -n "$git_repo" ]; do
        repo_clone "$repo_url$git_repo"
    done < list.txt
    rm -rfv list.txt
}

function go_get_list() {
    pkgs_list="$1"

    wget "$pkgs_list" -O list.txt
    while ISC='' read -r gpkg_path || [ -n "$gpkg_path" ]; do
        go get -v -u "$gpkg_path"
    done < list.txt
    rm -rfv list.txt
}

# Welcome
print_step "Script is now running, do not touch anything until it finishes :)"

# Password-less user
print_step "Setting password-less user (EXTREMELY INSANE STUFF)"
## Remove password for Casa
sudo passwd -du casa
## Add nullok option to PAM files
sudo find /etc/pam.d/* -exec sed -i {} -e "s/try_first_pass nullok/try_first_pass/g" \
                                       -e "s/pam_unix.so/pam_unix.so nullok/g" \;

# Manage repositories
print_step "Switching to Unstable repository"
## Remove Solus (Shannon)
sudo eopkg remove-repo -y Solus
## Add Unstable
sudo eopkg add-repo -y Solus https://packages.solus-project.com/unstable/eopkg-index.xml.xz

# Manage packages
## Upgrade the system
print_step "Getting system up to date"
sudo eopkg upgrade -y
## Install third party stuff
print_step "Installing third party packages"
tpkg_list "$LISTS_RAW_URL/third_party.txt"
## Install extra applications and stuff
print_step "Installing more packages"
sudo eopkg install -y caja-extensions galculator simplescreenrecorder libreoffice-all zsh \
                      git{,-extras} hub yarn neofetch yadm golang solbuild{,-config-unstable}

# Development packages and Solbuild
## Install development component
print_step "Installing development component and extra development packages"
sudo eopkg install -y -c system.devel
## Set up solbuild
print_step "Setting up solbuild"
sudo solbuild init -u

# Dotfiles
print_step "Setting-up dotfiles"
## Fixes
### Clean already present files
rm -rfv ~/.config/gtk-3.0/bookmarks
## Clone the repository and decrypt the binary
yadm clone -f https://github.com/feskyde/dotfiles
yadm decrypt
## Default to ZSH
sudo chsh -s /bin/zsh casa

# Git repositories
print_step "Cloning repositories"
enter_folder ~/Git
## GitHub repositories
clone_list "$LISTS_RAW_URL/github_repos.txt" https://github.com/
## Extra repositories
clone_list "$LISTS_RAW_URL/extra_repos.txt"
## Return to home
cd ~ || exit

# System configuration
print_step "Installing system configuration files"
enter_folder ~/Git/solus-stuff/config
bash bootstrap.sh
## Return to home
cd ~ || exit

# Solus packaging repository
## Create packages folder
print_step "Setting up Solus packages folder"
enter_folder ~/Git/packages
## Clone common repository
print_step "Clonning common repository"
while true; do
    if [ ! -d common ]; then
        repo_clone https://git.solus-project.com/common
    else
        break
    fi
done
## Link makefiles
print_step "Linking makefiles"
ln -srfv common/Makefile.common Makefile.common
ln -srfv common/Makefile.iso Makefile.iso
ln -srfv common/Makefile.toplevel Makefile
## Clone all source repositories
print_step "Clonning all source repositories"
make clone
## Return to home
cd ~ || exit

# Package Control
print_step "Installing package control"
## Enter to Sublime packages folder
enter_folder ~/.config/sublime-text-3/Installed\ Packages
## Download the package
wget https://packagecontrol.io/Package%20Control.sublime-package -O Package\ Control.sublime-package
## Back to home
cd ~ || exit

# Telegram Desktop
print_step "Installing Telegram Desktop"
## Enter into the Telegram folder
enter_folder ~/.TelegramDesktop
## Download the tarball
wget https://tdesktop.com/linux/current?alpha=1 -O telegram-desktop.tar.xz
## Unpack it
tar xfv telegram-desktop.tar.xz --strip-components=1 --show-transformed-names
rm -rfv telegram-desktop.tar.xz
## Back to home
cd ~ || exit

# Deezloader App
print_step "Setting-up Deezloader App"
enter_folder ~/Git/deezloader-app
yarn install
## Back to home
cd ~ || exit

# Go packages
print_step "Installing Go packages"
## Fixes
### Export GOPATH so the Go packages installation will not go KABOOM!
export GOPATH=$HOME/.golang
## Install packages
go_get_list "$LISTS_RAW_URL/go_packages.txt"
## Install gometalinter linters
$GOPATH/bin/gometalinter --install

# FINISHED!
print_step "Script has finished! You should reboot as soon as possible"
