#!/usr/bin/env bash
#
# Solus MATE Post Install Script
#

# Variables

## Repositories
### Names
REPO_SHANNON_NAME="Solus"
### URLs
REPO_UNSTABLE_URL="https://packages.solus-project.com/unstable/eopkg-index.xml.xz"

## Third Party
### Source
TPARTY_SOURCE="https://raw.githubusercontent.com/solus-project/3rd-party/master"

## Git
### Repositories path
REPOS_PATH="$HOME/Git"

## Personal Git repositories
### User URL
PERSONAL_URL="https://github.com/feskyde"
### User repositories
PERSONAL_REPOS=("deezloader" "stuff")
### Locations
#### Stuff (including system files and install scripts)
STUFF_DEST="$REPOS_PATH/stuff"
SYSFILES_PATH="$STUFF_DEST/system"

## Dotfiles
### Dotfiles URL
DOTFILES_SOURCE="$PERSONAL_URL/dotfiles"

## Solus packaging
### Main Solus Git URL
SOLUS_URL="https://git.solus-project.com"
### Packages Git URL
PACKAGES_URL="$SOLUS_URL/packages"
### Packages I maintain
PACKAGES_REPOS=("asciinema" "gnome-pomodoro" "gnome-sound-recorder" "gnome-twitch" "gourmet" "hub" "jq" "python-greenlet" "python-msgpack" "python-neovim" "python-notify2" "python-setproctitle" "python-sqlalchemy" "python-trollius" "xaut" "xdotool" "zuki-themes" "sc-controller")
### Locations
#### Packaging path
PACKAGING_PATH="$REPOS_PATH/packaging"
#### Common repository
COMMON_URL="$SOLUS_URL/common"
COMMON_PATH="$PACKAGING_PATH/common"

## Telegram Desktop
### Download URL
TELEGRAM_URL="https://tdesktop.com/linux/current?alpha=1"
### Destination
TELEGRAM_FOLDER="$HOME/.TelegramDesktop"
TELEGRAM_FILE="$TELEGRAM_FOLDER/telegram-alpha.tar.xz"
### Destination path
TELEGRAM_PATH="$TELEGRAM_FOLDER/$TELEGRAM_FILE"

# Functions
notify_me() {
    # Usage: notify_me [message]
    # Print the [message] and send a notification
    message="$1"

    echo -e "\e[1m>> $message\e[0m"
    notify-send "Solus MATE Post Install" "$message" -i distributor-logo-solus
}

enter_dir() {
    # Usage: enter_dir [directory]
    # Enter into a [directory], if it does not
    # exists, just create it
    directory="$1"

    notify_me "Entering in directory: $directory"
    if [ ! -d "$directory" ]; then
      mkdir -pv "$directory"
    fi
    cd "$directory" || exit
}

tparty_get() {
    # Usage: tparty_get [component] [package]
    # Build and install a third-party package
    # with the given [component] and [package]
    component="$1"
    package="$2"

    sudo eopkg build -y --ignore-safety "$TPARTY_SOURCE"/"$component"/"$package"/pspec.xml
    sudo eopkg install -y "$package"*.eopkg
    sudo rm -rfv "$package"*.eopkg
}

clone_list() {
    # Usage: clone_list [url] [list]
    # Clone every item on [list] using the Git
    # repositories from [url] as main url
    url="$1"
    list="$2"

    for repo in ${list[*]}; do
        notify_me "Cloning repository: $url/$repo"
        git clone --recursive "$url/$repo"
    done
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
### NPAPI Flash Player
tparty_get multimedia/video flash-player-npapi
### Microsoft Core Fonts
tparty_get desktop/font mscorefonts
## Install more applications and stuff
notify_me "Installing more packages"
sudo eopkg install -y simplescreenrecorder libreoffice-all fish yadm git {python-,}neovim golang solbuild{,-config-unstable}
## Install development component
notify_me "Installing development component"
sudo eopkg install -y -c system.devel

# Git repositories
notify_me "Creating Git directory"
enter_dir "$REPOS_PATH"

# Personal Git repositories
## Clone my repositories
notify_me "Cloning personal Git repositories"
clone_list "$PERSONAL_URL" "${PERSONAL_REPOS[*]}"
## Return to home
cd || exit

# Solus packaging repository
## Create Solus packaging directory
notify_me "Setting up Solus packaging directory"
enter_dir "$PACKAGING_PATH"
## Clone common repository
notify_me "Cloning common repository"
while true; do
    if [ ! -d "$COMMON_PATH" ]; then
        git clone "$COMMON_URL" "$COMMON_PATH"
    else
        break
    fi
done
## Link Makefile(s)
notify_me "Linking Makefiles"
ln -srfv "$COMMON_PATH/Makefile.common" "$PACKAGING_PATH/Makefile.common"
ln -srfv "$COMMON_PATH/Makefile.toplevel" "$PACKAGING_PATH/Makefile"
ln -srfv "$COMMON_PATH/Makefile.iso" "$PACKAGING_PATH/Makefile.iso"
## Clone my packages
notify_me "Cloning my packages"
clone_list "$PACKAGES_URL" "${PACKAGES_REPOS[*]}"
## Return to home
cd || exit

# Dotfiles
## Install the dotfiles
notify_me "Setting-up dotfiles"
yadm clone "$DOTFILES_SOURCE"
yadm decrypt
## Set default shell
notify_me "Setting default shell"
sudo chsh -s "$(which fish)" "$(whoami)"

# Telegram Desktop
notify_me "Installing Telegram Desktop"
## Download the tarball
curl -kLo "$TELEGRAM_PATH" --create-dirs "$TELEGRAM_URL"
## Enter into the Telegram directory
enter_dir "$TELEGRAM_FOLDER"
## Unpack it
tar xfv "$TELEGRAM_PATH"
rm -rfv "$TELEGRAM_PATH"
## Back to home
cd || exit

# System files
notify_me "Installing system files"
bash "$SYSFILES_PATH/bootstrap.sh"

# Solbuild
notify_me "Setting up solbuild"
sudo solbuild init -u

# FINISHED!
notify_me "Script has finished! You should reboot as soon as possible"
