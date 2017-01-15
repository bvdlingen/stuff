#!/usr/bin/env bash
#
# Solus Post Install Script
#

# Variables

## Repositories
### Names
REPO_SHANNON_NAME="Solus"
### URLs
REPO_UNSTABLE_URL="https://packages.solus-project.com/unstable/eopkg-index.xml.xz"

## Third Party
### Source
THIRD_PARTY_URL="https://raw.githubusercontent.com/solus-project/3rd-party/master"

## Git
### Repositories path
GIT_DIR="$HOME/Git"
### The main directory struct for this script
STUFF_DIR="$GIT_DIR/stuff"
CONFIGS_DIR="$STUFF_DIR/config"
FILES_DIR="$STUFF_DIR/files"

## GitHub repositories
### GitHub main URL
GITHUB_URL="https://github.com"
### Repositories list
GITHUB_REPO_LIST="$FILES_DIR/github_repos.txt"

## Solus repositories
### Solus Git main URL
SOLUS_URL="https://git.solus-project.com"
### Repositories list
SOLUS_REPO_LIST="$FILES_DIR/solus_repos.txt"
### Locations
#### Packaging path
PACKAGES_DIR="$GIT_DIR/packages"
#### Common repository
COMMON_REPO_DIR="$PACKAGING_DIR/common"

## Dotfiles
### Dotfiles URL
DOTFILES_URL="$PERSONAL_URL/dotfiles"

## Telegram Desktop
### Download URL
TELEGRAM_URL="https://tdesktop.com/linux/current?alpha=1"
### Destination
TELEGRAM_FOLDER="$HOME/.TelegramDesktop"
TELEGRAM_TARBALL="$TELEGRAM_FOLDER/telegram-desktop.tar.xz"

## Go packages
### Go packages list
GO_PACKAGES_LIST="$FILES_DIR/go_packages.txt"

# Functions
function notify_me() {
    # Usage: notify_me [message]
    # Print the [message] and send a notification
    message="$1"

    echo -e "\e[1m>> $message\e[0m"
    notify-send "Solus Post Install" "$message" -i distributor-logo-solus
}

function create_dir() {
    # Usage: create_dir [directory]
    # Create a [directory]
    directory="$1"

    if [ ! -d "$directory" ]; then
        notify_me "Creating directory: $directory"
        mkdir -pv "$directory"
    fi
}

function enter_dir() {
    # Usage: enter_dir [directory]
    # Enter into a [directory], if it does not
    # exists, just create it
    directory="$1"

    create_dir "$directory"
    notify_me "Entering in directory: $directory"
    cd "$directory" || exit
}

function close_dir() {
    # Usage: close_dir
    # Return to $HOME

    cd || exit
}

function clone_repo() {
    # Usage: clone_repo [url] [repo] {dest}
    # Clone a Git repository, if the clone fails,
    # start again, if {dest} is specified, clone into it
    url="$1"
    repo="$2"
    if [ -z "$3" ]; then
        dest="$3"
    else
        dest="$2"
    fi

    notify_me "Cloning repository: $url/$repo to $dest"
    while true; do
        if [ ! -d "$repo" ]; then
            git clone --recursive "$url/$repo" "$dest"
        else
            break
        fi
    done
}

function tparty_get_list() {
    # Usage: get_third_party_list [list]
    # Build and install third party packages
    # from the given [list]
    list="$1"

    while ISC='' read -r package || [ -n "$package" ]; do
        enter_dir build
        sudo eopkg build -y --ignore-safety "$THIRD_PARTY_URL"/"$package"/pspec.xml
        sudo eopkg install -y ./*.eopkg
        sudo rm -rfv ./*.eopkg
        close_dir
        rm -rfv build
    done < "$list"
}

function clone_list() {
    # Usage: clone_list [url] [list]
    # Clone every item on [list] file using the
    # Git repositories from [url] as main URL
    url="$1"
    list="$2"

    while ISC='' read -r repo || [ -n "$repo" ]; do
        clone_repo "$url/$repo" "$repo"
    done < "$list"
}

function go_get_list() {
    # Usage: go_get_list [list]
    # Get every package listed in the file [list]
    list="$1"

    while ISC='' read -r package || [ -n "$package" ]; do
        notify_me "Installing Go package: $package"
        go get -u "$package"
    done < "$list"
}

# Welcome
notify_me "Script is now running, do not touch anything until it finishes :)"

# Password-less user
## Remove password for Casa
notify_me "Setting password-less user"
sudo passwd -du "$(whoami)"
## Add nullok option to PAM files
notify_me "Adding nullok option to PAM files (EXTREMELY INSANE STUFF)"
sudo sed -e "s/sha512 shadow try_first_pass nullok/sha512 shadow try_first_pass/g" -i /etc/pam.d/system-password
sudo sed -e "s/pam_unix.so/pam_unix.so nullok/g" -i /etc/pam.d/*

# Manage repositories
## Remove Solus (Shannon)
notify_me "Removing $REPO_SHANNON_NAME repository"
sudo eopkg remove-repo -y "$REPO_SHANNON_NAME"
## Add Unstable
notify_me "Adding Unstable repository"
sudo eopkg add-repo -y "$REPO_SHANNON_NAME" "$REPO_UNSTABLE_URL"

# Manage packages
## Upgrade the system
notify_me "Getting system up to date"
sudo eopkg upgrade -y
## Install third party stuff
tparty_get_list "$FILES_DIR/third_party.txt"
## Install more applications and stuff
notify_me "Installing more packages"
sudo eopkg install -y budgie-{screenshot,haste}-applet gimp inkscape brasero cheese simplescreenrecorder kodi libreoffice-all zsh yadm git{,-extras} hub {python-,}neovim golang hugo solbuild{,-config-unstable} glances neofetch
## Install development component
notify_me "Installing development component"
sudo eopkg install -y -c system.devel
## Set up solbuild
notify_me "Setting up solbuild"
sudo solbuild init -u

# Git repositories
notify_me "Creating Git directory"
create_dir "$GIT_DIR"

# GitHub repositories
## Clone repositories
notify_me "Cloning GithUB repositories"
enter_dir "$GIT_DIR"
clone_list "$GITHUB_URL" "$GITHUB_REPO_LIST"
## Return to home
close_dir

# Solus packaging repository
## Create packages directory
notify_me "Setting up Solus packages directory"
enter_dir "$PACKAGES_DIR"
## Clone package repositories
notify_me "Cloning package repositories"
clone_list "$SOLUS_URL" "$SOLUS_REPO_LIST"
## Link makefiles
notify_me "Linking makefiles"
ln -srfv "$COMMON_REPO_DIR/Makefile.common" "$PACKAGING_DIR/Makefile.common"
ln -srfv "$COMMON_REPO_DIR/Makefile.toplevel" "$PACKAGING_DIR/Makefile"
ln -srfv "$COMMON_REPO_DIR/Makefile.iso" "$PACKAGING_DIR/Makefile.iso"
## Return to home
close_dir

# Dotfiles
## Install the dotfiles
notify_me "Setting-up dotfiles"
yadm clone "$DOTFILES_URL"
yadm decrypt
## Set default shell
notify_me "Setting default shell"
sudo chsh -s "$(which zsh)" "$(whoami)"

# Stateless configuration files
notify_me "Installing stateless configuration files"
bash "$CONFIGS_DIR/install.sh"

# Telegram Desktop
notify_me "Installing Telegram Desktop"
## Enter into the Telegram directory
enter_dir "$TELEGRAM_FOLDER"
## Download the tarball
curl -kLo "$TELEGRAM_URL"
## Unpack it
tar xfv "$TELEGRAM_TARBALL" --strip-components=1 --show-transformed-names
rm -rfv "$TELEGRAM_TARBALL"
## Back to home
close_dir

# Go packages
notify_me "Installing Go packages"
go_get_list "$GO_PACKAGES_LIST"

# Personalization
## Make GSettings set things
notify_me "Setting stuff with GSettings"
### Privacy
gsettings set org.gnome.desktop.privacy remove-old-temp-files true
gsettings set org.gnome.desktop.privacy remove-old-trash-files true
### Location
gsettings set org.gnome.system.location enabled true
### Sounds
gsettings set org.gnome.desktop.sound event-sounds true
gsettings set org.gnome.desktop.sound input-feedback-sounds true
gsettings set org.gnome.desktop.sound theme-name "freedesktop"
### Window manager
gsettings set org.gnome.desktop.wm.preferences num-workspaces 1

# FINISHED!
notify_me "Script has finished! You should reboot as soon as possible"
