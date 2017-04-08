#!/usr/bin/env bash
#
# Solus MATE Post Install Script
#

# Variables
## Lists (bad design is bad)
LISTS_RAW_URL="https://raw.githubusercontent.com/feddasch/things/master/lists"
## Third Party specs
SPECS_RAW_URL="https://raw.githubusercontent.com/solus-project/3rd-party/master"
## Project directory
PROJECT_DIR="$HOME/Proyectos"

# Functions
function notify_step() {
    message="$1"

    echo -e ">> $message"
    notify-send "Solus MATE Post Install Script" "$message" -i distributor-logo-solus
}

function check_folder() {
    folder="$1"

    if [ ! -d "$folder" ]; then
        echo -e "- Creating folder: $folder"
        mkdir -pv "$folder"
    fi
}

function check_root_folder() {
    root_folder="$1"

    if [ ! -d "$root_folder" ]; then
        echo -e "- Creating folder: $root_folder"
        sudo mkdir -pv "$root_folder"
    fi
}

function enter_folder() {
    enter="$1"

    check_folder "$enter"
    cd "$enter" || exit
    echo -e "- Now in folder: $enter"
}

function list_tp_install() {
    third_list="$1"

    wget "$third_list" -O list_tpkg.txt
    while ISC='' read -r tpkg_dir || [ -n "$tpkg_dir" ]; do
        echo -e "- Installing third-party package: $tpkg_dir"
        sudo eopkg build -y --ignore-safety "$SPECS_RAW_URL"/"$tpkg_dir"/pspec.xml
        sudo eopkg install -y ./*.eopkg
        rm -rfv ./*.eopkg
    done < list_tpkg.txt
    rm -rfv list_tpkg.txt
}

function list_git_clone() {
    repo_list="$1"

    wget "$repo_list" -O list_clone.txt
    while ISC='' read -r git_repo || [ -n "$git_repo" ]; do
        echo -e "- Clonning repository: $git_repo"
        git clone --recursive "$git_repo"
    done < list_clone.txt
    rm -rfv list_clone.txt
}

function list_go_get() {
    pkgs_list="$1"

    wget "$pkgs_list" -O list_go_get.txt
    while ISC='' read -r gpkg_path || [ -n "$gpkg_path" ]; do
        echo -e "- Installing Go package: $gpkg_path"
        go get -v -u "$gpkg_path"
    done < list_go_get.txt
    rm -rfv list_go_get.txt
}

function conf_install() {
    src="$1"
    dst="$2"

    check_root_folder "$(dirname "$dst")"
    sudo cp -rfv "$src" "$dst"
}

# Welcome
notify_step "Script is now running, do not touch anything until it finishes :)"

# Password-less user (EXTREMELY INSANE STUFF)
notify_step "Setting password-less user"
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
sudo eopkg add-repo -y Solus https://packages.solus-project.com/unstable/eopkg-index.xml.xz

# Manage packages
## Remove unneded stuff
sudo eopkg remove --purge firefox thunderbird arc-firefox-theme
## Upgrade the system
notify_step "Getting the system up to date"
sudo eopkg upgrade -y
## Install third party stuff
notify_step "Installing third party packages"
list_tp_install "$LISTS_RAW_URL/solus/third_party.txt"
## Install extra applications and stuff
notify_step "Installing more packages"
sudo eopkg install -y caja-extensions geary libreoffice-all kodi vscode fish neofetch git{,-extras} yadm golang solbuild{,-config{,-local}-unstable}
## Install development component
notify_step "Installing development component"
sudo eopkg install -y -c system.devel
## Set up Solbuild
notify_step "Setting up solbuild"
sudo solbuild init -u

# Git repositories
## Switch to the projects directory
enter_folder "$PROJECT_DIR"
## Clone the repositories
notify_step "Cloning Git repositories"
list_git_clone "$LISTS_RAW_URL/common/git_repos.txt"
## Return to home
cd || exit

# Dotfiles
notify_step "Setting-up dotfiles"
## Clone the repository and decrypt the binary
yadm clone -f https://github.com/feddasch/dotfiles
yadm decrypt
## Link the VS Code directory to VS Code OSS directory
ln -rsfv "$HOME/.config/Code" "$HOME/.config/Code - OSS"
## Default to Fish
sudo chsh -s /usr/bin/fish casa

# System configuration
notify_step "Setting up configuration files"
## Set up the files
enter_folder "$PROJECT_DIR/things/solus/config"
conf_install lightdm/lightdm.conf /etc/lightdm/lightdm.conf
## Return to home
cd || exit

# Solus packaging repository
## Create packages folder
notify_step "Setting up Solus packages folder"
enter_folder "$PROJECT_DIR/Solus/repository"
## Clone common repository
notify_step "Clonning common repository"
while true; do # FUCKING CLONE IT
    if [ ! -d common ]; then
        git clone --recursive https://git.solus-project.com/common
    else
        break
    fi
done
## Link makefiles
notify_step "Linking makefiles"
ln -rsfv common/Makefile.toplevel Makefile
ln -rsfv common/Makefile.common   Makefile.common
ln -rsfv common/Makefile.iso      Makefile.iso
## Clone all source repositories
notify_step "Clonning all source repositories"
make clone -j100
## Return to home
cd || exit

# Telegram Desktop
notify_step "Installing Telegram Desktop"
## Enter into the Telegram folder
enter_folder "$HOME/.TelegramDesktop"
## Download the tarball
wget https://tdesktop.com/linux/current?alpha=1 -O telegram-desktop.tar.xz
## Unpack it
tar xfv telegram-desktop.tar.xz --strip-components=1 --show-transformed-names
rm -rfv telegram-desktop.tar.xz
## Back to home
cd || exit

# Go packages
notify_step "Installing Go packages"
## Fixes
### Create GOPATH so the Go packages installation will not go KABOOM!
export GOPATH="$HOME/.golang"
enter_folder "$GOPATH"
## Install packages
list_go_get "$LISTS_RAW_URL/common/go_packages.txt"
## Link my repository to the projects directory
ln -rsfv "$GOPATH/src/github.com/feddasch/"* "$PROJECT_DIR"
## Back to home
cd || exit

# FINISHED!
notify_step "Script has finished! You should reboot as soon as possible"
