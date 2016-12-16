#!/usr/bin/env bash
#
# Solus Post Install Script
#

# Variables

## Repositories
### Names
REPOSITORY_SHANNON_NAME="Solus"
### URLs
REPOSITORY_UNSTABLE_URL="https://packages.solus-project.com/unstable/eopkg-index.xml.xz"

## Third Party
### Source
THIRD_PARTY_SOURCE="https://raw.githubusercontent.com/solus-project/3rd-party/master"

## Git
### Repositories path
GIT_REPOS_PATH="$HOME/Git"

## Personal Git repositories
### User URL
PERSONAL_GIT_URL="https://github.com/feskyde"
### User repositories
PERSONAL_GIT_REPOS=("deezloader" "stuff")
### Locations
#### Stuff (including system files and install scripts)
STUFF_REPO_PATH="$GIT_REPOS_PATH/stuff"
SYSFILES_PATH="$STUFF_REPO_PATH/system"

## Dotfiles
### Dotfiles URL
DOTFILES_GIT_URL="$PERSONAL_GIT_URL/dotfiles"

## Solus packaging
### Main Solus Git URL
SOLUS_GIT_URL="https://git.solus-project.com"
### Locations
#### Packages
PACKAGES_PATH="$GIT_REPOS_PATH/packages"
#### Common repository
COMMON_REPO_URL="$SOLUS_GIT_URL/common"
COMMON_REPO_PATH="$PACKAGES_PATH/common"

## Telegram Desktop
### Download URL
TELEGRAM_URL="https://tdesktop.com/linux/current"
### Destination
TELEGRAM_FOLDER="$HOME/.TelegramDesktop"
TELEGRAM_FILE="$TELEGRAM_FOLDER/telegram-alpha.tar.xz"
### Destination path
TELEGRAM_DEST_PATH="$TELEGRAM_FOLDER/$TELEGRAM_FILE"

# Functions
notify_me() {
    # Usage: notify_me [message]
    # Print the [message] and send a notification
    message="$1"

    echo "\e[1m>> $message\e[0m"
    notify-send "Post Install" "$message" -i distributor-logo-solus
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

    sudo eopkg build -y --ignore-safety "$THIRD_PARTY_SOURCE"/"$component"/"$package"/pspec.xml
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
notify_me "Removing $REPOSITORY_SHANNON_NAME repository"
sudo eopkg remove-repo -y "$REPOSITORY_SHANNON_NAME"
## Add Unstable
notify_me "Adding Unstable repository"
sudo eopkg add-repo -y "$REPOSITORY_SHANNON_NAME" "$REPOSITORY_UNSTABLE_URL"

# Manage packages
## Remove unneeded packages
notify_me "Removing unneeded packages"
#shellcheck disable=SC1083
sudo eopkg remove -y --purge orca {arc,moka,faba{,-mono}}-icon-theme
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
sudo eopkg install -y paper-icon-theme budgie-{screenshot,haste}-applet obs-studio libreoffice-all fish yadm git {python-,}neovim golang solbuild{,-config-unstable}

# Development component
notify_me "Installing development component"
sudo eopkg install -y -c system.devel

# Git repositories
notify_me "Creating Git directory"
enter_dir "$GIT_REPOS_PATH"

# Personal Git repositories
## Clone my repositories
notify_me "Cloning personal Git repositories"
clone_list "$PERSONAL_GIT_URL" "${PERSONAL_GIT_REPOS[*]}"
## Return to home
cd || exit

# Solus packaging repository
## Create Solus packaging directory
notify_me "Setting up Solus packaging directory"
enter_dir "$PACKAGES_PATH"
## Clone common repository
notify_me "Cloning common repository"
while true; do
    if [ ! -d "$COMMON_REPO_PATH" ]; then
        git clone "$COMMON_REPO_URL" "$COMMON_REPO_PATH"
    else
        break
    fi
done
## Link Makefile(s)
notify_me "Linking Makefiles"
ln -srfv "$COMMON_REPO_PATH/Makefile.common" "$PACKAGES_PATH/Makefile.common"
ln -srfv "$COMMON_REPO_PATH/Makefile.toplevel" "$PACKAGES_PATH/Makefile"
ln -srfv "$COMMON_REPO_PATH/Makefile.iso" "$PACKAGES_PATH/Makefile.iso"
## Return to home
cd || exit

# Dotfiles
## Install the dotfiles
notify_me "Setting-up dotfiles"
yadm clone "$DOTFILES_GIT_URL"
## Decrypt them
notify_me "Decrypting dotfiles"
yadm decrypt
## Set default shell
notify_me "Setting default shell"
sudo chsh -s "$(which fish)" "$(whoami)"

# Telegram Desktop
notify_me "Installing Telegram Desktop"
## Download the tarball
curl -kLo "$TELEGRAM_DEST_PATH" --create-dirs "$TELEGRAM_URL"
## Enter into the Telegram directory
enter_dir "$TELEGRAM_FOLDER"
## Unpack it
tar xfv "$TELEGRAM_DEST_PATH"
rm -rfv "$TELEGRAM_DEST_PATH"
## Back to home
cd || exit

# Stupidly deployable system
## Install system files
notify_me "Installing system files"
bash "$SYSFILES_PATH/bootstrap.sh"

# solbuild
notify_me "Setting up solbuild"
sudo solbuild init -u

# Personalization
## Make GSettings set things
notify_me "Setting stuff with GSettings"
### Interface
gsettings set org.gnome.desktop.interface icon-theme "Paper"
gsettings set org.gnome.desktop.interface cursor-theme "Paper"
### Background
gsettings set org.gnome.desktop.background picture-uri "file:///usr/share/backgrounds/solus/TullamoreGrandCanal.jpg"
gsettings set org.gnome.desktop.screensaver picture-uri "file:///usr/share/backgrounds/solus/TullamoreGrandCanal.jpg"
### Privacy
gsettings set org.gnome.desktop.privacy remove-old-temp-files true
gsettings set org.gnome.desktop.privacy remove-old-trash-files true
### Location
gsettings set org.gnome.system.location enabled true
### Sounds
gsettings set org.gnome.desktop.sound event-sounds true
gsettings set org.gnome.desktop.sound input-feedback-sounds true
gsettings set org.gnome.desktop.sound theme-name "freedesktop"
### Terminal
gsettings set org.gnome.Terminal.Legacy.Settings theme-variant "dark"
gsettings set org.gnome.Terminal.Legacy.Settings new-terminal-mode "tab"
### Window manager
gsettings set org.gnome.desktop.wm.preferences num-workspaces 1

# FINISHED!
notify_me "Script has finished! You should reboot as soon as possible"
