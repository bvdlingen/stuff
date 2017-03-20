#!/usr/bin/env bash
#
# Solus Post Install Script
#

# Lists (bad design is bad)
LISTS_RAW_URL="https://raw.githubusercontent.com/feskyde/solus-stuff/master/lists"
# Third Party specs
SPECS_RAW_URL="https://raw.githubusercontent.com/solus-project/3rd-party/master"

# Functions
function notify_step() {
    message="$1"

    printf "\n>> %s\n" "$message"
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

function go_get_from_list() {
    pkgs_list="$1"

    wget "$pkgs_list" -O list_go_get.txt
    while ISC='' read -r gpkg_path || [ -n "$gpkg_path" ]; do
        printf "\e[1m  - Installing Go package: %s\e[0m\n" "$gpkg_path"
        go get -v -u "$gpkg_path"
    done < list_go_get.txt
    rm -rfv list_go_get.txt
}

# Welcome
notify_step "Script is now running, do not touch anything until it finishes :)"

# Password-less user
notify_step "Setting password-less user (EXTREMELY INSANE STUFF)"
## Remove password for Casa
sudo passwd -du casa
## Add nullok option to PAM files
sudo find /etc/pam.d -name "*" -exec sed -i {} -e "s:try_first_pass nullok:try_first_pass:g" \
                                               -e "s:pam_unix.so:pam_unix.so nullok:g" \;

# Manage repositories
notify_step "Switching to Unstable repository"
## Remove Solus (Shannon)
sudo eopkg remove-repo -y Solus
## Add Unstable
sudo eopkg add-repo -y Unstable https://packages.solus-project.com/unstable/eopkg-index.xml.xz

# Manage packages
## Remove unneded stuff
sudo eopkg remove --purge firefox thunderbird arc-firefox-theme
## Upgrade the system
notify_step "Getting system up to date"
sudo eopkg upgrade -y
## Install third party stuff
notify_step "Installing third party packages"
third_party_install_from_list "$LISTS_RAW_URL/solus/third_party.txt"
## Install extra applications and stuff
notify_step "Installing more packages"
sudo eopkg install -y geary simplescreenrecorder libreoffice-all vscode zsh git{,-extras} yadm golang yarn solbuild{,-config-unstable}

# Development packages and Solbuild
## Install development component
notify_step "Installing development component"
sudo eopkg install -y -c system.devel

# Dotfiles
notify_step "Setting-up dotfiles"
## Clone the repository and decrypt the binary
yadm clone -f https://github.com/feskyde/dotfiles
yadm decrypt
## Default to ZSH
sudo chsh -s /bin/zsh casa

# Git repositories
notify_step "Cloning repositories"
checkout_folder ~/Projectos
## GitHub repositories
clone_repositories_from_list "$LISTS_RAW_URL/common/git_repos.txt"
## Return to home
cd ~ || exit

# Solus packaging repository
## Create packages folder
notify_step "Setting up Solus packages folder"
checkout_folder ~/Projectos/packages
## Clone common repository
notify_step "Clonning common repository"
while true; do
    if [ ! -d common ]; then
        git clone --recursive https://git.solus-project.com/common
    else
        break
    fi
done
## Link makefiles
notify_step "Linking makefiles"
ln -srfv common/Makefile.common Makefile.common
ln -srfv common/Makefile.iso Makefile.iso
ln -srfv common/Makefile.toplevel Makefile
## Clone all source repositories
notify_step "Clonning all source repositories"
make clone -j50
## Return to home
cd ~ || exit

# System configuration
notify_step "Installing system configuration files"
checkout_folder ~/Projectos/solus-stuff/config
bash setup.sh
## Return to home
cd ~ || exit

# Telegram Desktop
notify_step "Installing Telegram Desktop"
## Enter into the Telegram folder
checkout_folder ~/.TelegramDesktop
## Download the tarball
wget https://tdesktop.com/linux/current?alpha=1 -O telegram-desktop.tar.xz
## Unpack it
tar xfv telegram-desktop.tar.xz --strip-components=1 --show-transformed-names
rm -rfv telegram-desktop.tar.xz
## Back to home
cd ~ || exit

# Deezloader
notify_step "Setting-up Deezloader App"
## Enter into the repo folder and yarn-ize
checkout_folder ~/Projectos/deezloader-app
yarn install
## Back to home
cd ~ || exit

# Go packages
notify_step "Installing Go packages"
## Fixes
### Create GOPATH so the Go packages installation will not go KABOOM!
export GOPATH="$(realpath ~)/.golang"
checkout_folder "$GOPATH"
cd ~ || exit
## Install packages
go_get_from_list "$LISTS_RAW_URL/common/go_packages.txt"
## Install linters
~/.golang/bin/gometalinter --install

# Solbuild
notify_step "Setting up solbuild"
sudo solbuild init -u

# FINISHED!
notify_step "Script has finished! You should reboot as soon as possible"
