#!/usr/bin/env bash
#
# Solus MATE Post Install Script (feddasch)
#

# Variables
## Lists (bad design is bad)
LISTS_RAW_URL="https://raw.githubusercontent.com/feddasch/things/master/lists"
## Project directory
PROJECT_DIR="$HOME/Proyectos"

# Functions
notify_step() {
    echo -e ">> $1"
    notify-send "Solus MATE Post Install Script (feddasch)" "$1" -i distributor-logo-solus
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
        git clone --recursive "$repository"
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
## Link the VS Code directory to VS Code OSS directory
ln -rsfv "$HOME/.config/Code" "$HOME/.config/Code - OSS"
## Default to Fish
sudo chsh -s $(which fish) $(whoami)

# Git repositories
## Switch to the projects directory
enter_folder "$PROJECT_DIR"
## Clone the repositories
notify_step "Cloning Git repositories"
list_git_clone "$LISTS_RAW_URL/common/git_repos.txt"
## Return to home
cd || exit

# Packaging
## Install development packages
notify_step "Installing development component"
sudo eopkg install -y -c system.devel
## Set up Solbuild
notify_step "Setting up solbuild"
sudo solbuild init -u
## Create packages folder
notify_step "Setting up Solus packages folder"
enter_folder "$PROJECT_DIR/Solus"
## Clone common repository
notify_step "Clonning common repository"
git clone https://git.solus-project.com/common
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
## Install it
notify_step "Installing Telegram Desktop"
enter_folder "$HOME/.TelegramDesktop"
tar xJv --strip-components=1 --show-transformed-names < <(curl -sL "https://tdesktop.com/linux/current?alpha=1")
## Back to home
cd || exit

# Docker
## Add my user to docker group
notify_step "Adding this user to docker group"
sudo usermod -aG docker $(whoami)

# Go packages
## Fixes
### Create GOPATH so the Go packages installation will not go KABOOM!
export GOPATH="$HOME/.golang"
## Install packages
notify_step "Installing Go packages"
list_go_get "$LISTS_RAW_URL/common/go_packages.txt"
