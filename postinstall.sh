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
### Build folder
THIRD_PARTY_BUILD_FOLDER="$HOME/build"

## Git
### Repositories folder
GIT_FOLDER="$HOME/Git"
### The main folder struct for this script
STUFF_FOLDER="$GIT_FOLDER/stuff"
CONFIGS_FOLDER="$STUFF_FOLDER/config"
FILES_FOLDER="$STUFF_FOLDER/files"

## GitHub repositories
### GitHub main URL
GITHUB_URL="https://github.com"
### Repositories list
GITHUB_REPO_LIST="$FILES_FOLDER/github_repos.txt"

## Solus repositories
### Solus Git main URL
SOLUS_URL="https://git.solus-project.com"
### Repositories list
SOLUS_REPO_LIST="$FILES_FOLDER/solus_repos.txt"
### Locations
#### Packaging folder
PACKAGES_FOLDER="$GIT_FOLDER/packages"
#### Common repository
COMMON_REPO_FOLDER="$PACKAGING_FOLDER/common"

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
GO_PACKAGES_LIST="$FILES_FOLDER/go_packages.txt"

# Functions
function notify_me() {
    # Usage: notify_me [message]
    # Print the [message] and send a notification
    message="$1"

    echo -e "\e[1m>> $message\e[0m"
    notify-send "Solus Post Install" "$message" -i distributor-logo-solus
}

function folder_create() {
    # Usage: folder_create [folder]
    # Create a [folder]
    folder="$1"

    if [ ! -d "$folder" ]; then
        notify_me "Creating folder: $folder"
        mkdir -pv "$folder"
    fi
}

function folder_enter() {
    # Usage: folder_enter [folder]
    # Enter into a [folder], if it does not
    # exists, just create it
    folder="$1"

    folder_create "$folder"
    notify_me "Entering in folder: $folder"
    cd "$folder" || exit
}

function folder_close() {
    # Usage: folder_close
    # Return to $HOME

    cd || exit
}

function folder_wipe() {
    # Usage: folder_wipe [folder]
    # Close and wipe the given [folder]
    folder="$1"

    folder_close
    rm -rfv "$folder"
}

function folder_npmi() {
    # Usage: folder_npmi [folder]
    # Execute npm install in the given [folder]
    folder="$1"

    folder_enter "$folder"
    notify_me "Installing NodeJS packages in folder: $folder"
    npm install
}

function tparty_get() {
    # Usage: tparty_get [package]
    # Build and install [package] from third party
    package="$1"

    folder_enter "$THIRD_PARTY_BUILD_FOLDER"
    sudo eopkg build -y --ignore-safety "$THIRD_PARTY_URL"/"$package"/pspec.xml
    sudo eopkg install -y ./*.eopkg
    folder_wipe "$THIRD_PARTY_BUILD_FOLDER"
}

function repo_clone() {
    # Usage: repo_clone [url] [repo] {dest}
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

function list_tparty_get() {
    # Usage: list_tparty_get [list]
    # Build and install third party packages
    # from the given [list]
    list="$1"

    while ISC='' read -r package || [ -n "$package" ]; do
        tparty_get "$package"
    done < "$list"
}

function list_clone() {
    # Usage: list_clone [url] [list]
    # Clone every item on [list] file using the
    # Git repositories from [url] as main URL
    url="$1"
    list="$2"

    while ISC='' read -r repo || [ -n "$repo" ]; do
        repo_clone "$url/$repo" "$repo"
    done < "$list"
}

function list_go_get() {
    # Usage: list_go_get [list]
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
list_tparty_get "$FILES_FOLDER/third_party.txt"
## Install more applications and stuff
notify_me "Installing more packages"
sudo eopkg install -y budgie-{screenshot,haste}-applet gimp inkscape brasero cheese simplescreenrecorder kodi libreoffice-all zsh yadm git{,-extras} hub glances neofetch {python-,}neovim golang nodejs solbuild{,-config-unstable}
## Install development component
notify_me "Installing development component"
sudo eopkg install -y -c system.devel
## Set up solbuild
notify_me "Setting up solbuild"
sudo solbuild init -u

# Git repositories
notify_me "Creating Git folder"
folder_create "$GIT_FOLDER"

# GitHub repositories
## Clone repositories
notify_me "Cloning GithUB repositories"
folder_enter "$GIT_FOLDER"
list_clone "$GITHUB_URL" "$GITHUB_REPO_LIST"
## Return to home
folder_close

# Solus packaging repository
## Create packages folder
notify_me "Setting up Solus packages folder"
folder_enter "$PACKAGES_FOLDER"
## Clone package repositories
notify_me "Cloning package repositories"
list_clone "$SOLUS_URL" "$SOLUS_REPO_LIST"
## Link makefiles
notify_me "Linking makefiles"
ln -srfv "$COMMON_REPO_FOLDER/Makefile.common" "$PACKAGING_FOLDER/Makefile.common"
ln -srfv "$COMMON_REPO_FOLDER/Makefile.iso" "$PACKAGING_FOLDER/Makefile.iso"
ln -srfv "$COMMON_REPO_FOLDER/Makefile.toplevel" "$PACKAGING_FOLDER/Makefile"
## Return to home
folder_close

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
bash "$CONFIGS_FOLDER/install.sh"

# Telegram Desktop
notify_me "Installing Telegram Desktop"
## Enter into the Telegram folder
folder_enter "$TELEGRAM_FOLDER"
## Download the tarball
curl -kLo "$TELEGRAM_URL"
## Unpack it
tar xfv "$TELEGRAM_TARBALL" --strip-components=1 --show-transformed-names
folder_wipe "$TELEGRAM_TARBALL"

# Go packages
notify_me "Installing Go packages"
list_go_get "$GO_PACKAGES_LIST"

# Blog
## Setup it
notify_me "Setting-up blog"
## Install Hexo
sudo npm install -g hexo-cli
## Install needed libraries
folder_npmi "$BLOG_FOLDER"
## Back to home
folder_close

# Deezloader App
## Setup it
notify_me "Setting-up Deezloader"
folder_enter "$GIT_FOLDER"
## Clone repository
repo_clone https://gitlab.com/ParadoxalManiak/deezloader-app
## Install needed libraries
folder_npmi "$GIT_FOLDER"/deezloader-app
## Back to home
folder_close

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
