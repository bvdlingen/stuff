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

## Git
### Repositories path
GIT_REPOS_PATH="Git"

## Personal Git repositories
### User URL
PERSONAL_GIT_URL="https://github.com/feskyde"
### User repositories
PERSONAL_GIT_REPOS=("deezloader" "stuff")
### Locations
#### Stuff (including system files and install scripts)
STUFF_REPO_PATH="$GIT_REPOS_PATH/stuff"
SYSFILES_PATH="$STUFF_REPO_PATH/solus/system"

## Dotfiles
### Dotfiles URL
DOTFILES_GIT_URL="$PERSONAL_GIT_URL/dotfiles"

## Solus packaging
### Main Solus Git URL
SOLUS_GIT_URL="https://git.solus-project.com"
### Locations
#### Common repository
COMMON_REPO_URL="$SOLUS_GIT_URL/common"
COMMON_REPO_PATH="$GIT_REPOS_PATH/common"
#### Packages
PACKAGES_PATH="$GIT_REPOS_PATH/packages"

## Telegram Desktop
### Download URL
TELEGRAM_SOURCE="current?alpha=1"
TELEGRAM_URL="https://tdesktop.com/linux/$TELEGRAM_SOURCE"
### Destination
TELEGRAM_PATH=".TelegramDesktop"
TELEGRAM_FILE="telegram-alpha.tar.xz"
### Destination path
TELEGRAM_DEST="$HOME/$TELEGRAM_PATH/$TELEGRAM_FILE"

# Functions
function notify_me() {
    # Usage: notify_me [message]
    # Print the [message] and send a notification
    message="$1"

    echo -e "\e[1m>> $message\e[0m"
    notify-send "Post Install" "$message" -i distributor-logo-solus
}

function enter_dir() {
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

function clone_list() {
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
sudo passwd -du casa
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
## Install more applications and stuff
notify_me "Installing more packages"
sudo eopkg install -y paper-icon-theme budgie-{screenshot,haste}-applet \
                      kodi brasero cheese obs-studio libreoffice-all    \
                      zsh yadm git hub neovim neofetch cargo solbuild   \
                      solbuild-config-unstable flash-player-nonfree

# Development component
notify_me "Installing development component"
sudo eopkg install -y -c system.devel

# Git repositories
notify_me "Creating Git directory"
enter_dir "$HOME/$GIT_REPOS_PATH"

# Personal Git repositories
## Clone my repositories
notify_me "Cloning personal Git repositories"
clone_list "$PERSONAL_GIT_URL" "${PERSONAL_GIT_REPOS[*]}"
## Return to home
cd "$HOME" || exit

# Solus packaging repository
## Create Solus packaging directory
notify_me "Setting up Solus packaging directory"
enter_dir "$HOME/$PACKAGES_PATH"
## Clone common repository
notify_me "Cloning common repository"
while true; do
    if [ ! -d "$HOME/$COMMON_REPO_PATH" ]; then
        git clone "$COMMON_REPO_URL" "$HOME/$COMMON_REPO_PATH"
    else
        break
    fi
done
## Link Makefile(s)
notify_me "Linking Makefiles"
ln -srfv "$HOME/$COMMON_REPO_PATH/Makefile.common" "$HOME/$PACKAGES_PATH/Makefile.common"
ln -srfv "$HOME/$COMMON_REPO_PATH/Makefile.toplevel" "$HOME/$PACKAGES_PATH/Makefile"
ln -srfv "$HOME/$COMMON_REPO_PATH/Makefile.iso" "$HOME/$PACKAGES_PATH/Makefile.iso"
## Return to home
cd "$HOME" || exit

# Dotfiles
notify_me "Setting-up dotfiles"
yadm clone "$DOTFILES_GIT_URL"

# Defaults
notify_me "Setting ZSH as default shell"
sudo chsh -s "$(which zsh)" casa

# Telegram Desktop
notify_me "Installing Telegram Desktop"
curl -kLo "$TELEGRAM_DEST" --create-dirs "$TELEGRAM_URL"
enter_dir "$TELEGRAM_PATH"
tar xfv "$TELEGRAM_DEST"
rm -rfv "$TELEGRAM_DEST"

# Stupidly deployable system
## Install system files
notify_me "Installing system files"
bash "$HOME/$SYSFILES_PATH/install.sh"

# Evobuild
notify_me "Setting up solbuild"
sudo solbuild init -u

# Personalization
## Make GSettings set things
notify_me "Setting stuff with GSettings"
### Interface
gsettings set org.gnome.desktop.interface icon-theme "Paper"
gsettings set org.gnome.desktop.interface cursor-theme "Paper"
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

# FINISHED!
notify_me "Script has finished! You SHOULD reboot as soon as possible"
