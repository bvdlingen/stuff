#!/usr/bin/env bash
#
# Solus Post Install Script (feddasch)
#

# Variables
## Lists (bad design is bad)
LISTS_RAW_URL="https://raw.githubusercontent.com/feddasch/things/master/lists"
## Project directory
PROJECT_DIR="$HOME/Proyectos"

# Functions
notify_step() {
    echo -e ">> $1"
    notify-send "Solus Post Install Script (feddasch)" "$1" -i distributor-logo-solus
}

notify_substep() {
    echo -e " - $1"
}

check_folder() {
    if ! test -d "$1"; then
        notify_substep "Creating folder: $1"
        mkdir -pv "$1"
    fi
}

enter_folder() {
    check_folder "$1"
    notify_substep "Entering to folder: $1"
    cd "$1" || exit
}

list_git_clone() {
    while read -r repository; do
        notify_substep "Clonning repository: $repository"
        git clone "$repository"
    done < <(curl -sL "$1")
}

list_get_source() {
    while read -r source; do
        notify_substep "Getting source: $repository"
        git clone "https://git.solus-project.com/packages/$source"
    done < <(curl -sL "$1")
}

list_go_get() {
    while read -r package; do
        notify_substep "Installing Go package: $package"
        go get -v -u "$package"
    done < <(curl -sL "$1")
}

# Welcome
notify_step "Script is now running, do not touch anything until it finishes :)"

# Dotfiles
notify_step "Setting-up dotfiles"
## Clone the repository and decrypt the binary
yadm clone -f https://github.com/feddasch/dotfiles
yadm decrypt
## Link the VS Code stuff to VS Code OSS's
ln -rsfv "$HOME/.config/Code" "$HOME/.config/Code - OSS"
## Set fish as the default shell
sudo chsh -s "$(which fish)" "$(whoami)"

# Git repositories
## Switch to the projects directory
enter_folder "$PROJECT_DIR"
## Clone the repositories
notify_step "Cloning Git repositories"
list_git_clone "$LISTS_RAW_URL/common/git_repos.txt"
## Return to home
cd || exit

# Packaging
## Create packages folder
notify_step "Setting up Solus packages folder"
enter_folder "$PROJECT_DIR/Solus"
## Clone common repository
notify_step "Clonning common repository"
while true; do
    if ! test -d common; then
        git clone https://git.solus-project.com/common
    fi
done
## Link makefiles
notify_step "Linking makefiles"
ln -rsfv common/Makefile.toplevel Makefile
ln -rsfv common/Makefile.common   Makefile.common
ln -rsfv common/Makefile.iso      Makefile.iso
## Get source repositories
notify_step "Getting source repositories"
list_get_source "$LISTS_RAW_URL/solus/package_sources.txt"
## Return to home
cd || exit

# Development packages
notify_step "Installing development component"
sudo eopkg install -y -c system.devel

# Solbuild
notify_step "Setting up solbuild"
sudo solbuild init -u

# Go packages
notify_step "Installing Go packages"
## Create GOPATH so the Go packages installation will not do KABOOM!
export GOPATH="$PROJECT_DIR/Go"
## Install the Go package list
list_go_get "$LISTS_RAW_URL/common/go_packages.txt"

# Telegram Desktop
notify_step "Installing Telegram Desktop"
bash < <(curl -sL "$SCRIPTS_RAW_URL/tdesktop-alpha.sh")

# Personalization
notify_step "Setting stuff with GSettings"
### Privacy
gsettings set org.gnome.desktop.privacy remove-old-temp-files true
gsettings set org.gnome.desktop.privacy remove-old-trash-files true
### Location
gsettings set org.gnome.system.location enabled true
### Sounds
gsettings set org.gnome.desktop.sound event-sounds true
gsettings set org.gnome.desktop.sound input-feedback-sounds true
gsettings set org.gnome.desktop.sound theme-name "freedesktop"
