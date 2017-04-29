#!/usr/bin/env bash
#
# Solus Post Install Script (casa)
#

# Variables
## GitHub raw files URL
RAW_URL="https://raw.githubusercontent.com/feddasch/things/master"
## Lists
LISTS_RAW_URL="$RAW_URL/lists"
## Scripts
SCRIPTS_RAW_URL="$RAW_URL/scripts"
## Third Party specs
SPECS_RAW_URL="https://raw.githubusercontent.com/solus-project/3rd-party/master"
## Project directory
PROJECT_DIR="$HOME/Proyectos"

# Functions
function notify_step() {
    echo -e ">> $1"
    notify-send "Solus Post Install Script (casa)" "$1" -i distributor-logo-solus
}

function notify_substep() {
    echo -e " - $1"
}

function enter_folder() {
    if ! test -d "$1"; then
        notify_substep "Creating folder: $1"
        mkdir -pv "$1"
    fi

    notify_substep "Entering to folder: $1"
    cd "$1" || exit
}

# Start
notify_step "Script is now running, do not touch anything until it finishes :)"

# Manage repositories
notify_step "Switching to Unstable repository"
## Remove Solus (Shannon)
sudo eopkg remove-repo -y Solus
## Add Unstable
sudo eopkg add-repo -y Solus https://packages.solus-project.com/unstable/eopkg-index.xml.xz

# Manage packages
## Remove unneded stuff
notify_step "Removing unneded stuff"
sudo eopkg remove -y --purge rhythmbox orca onboard
## Upgrade the system
notify_step "Getting the system up to date"
sudo eopkg upgrade -y
## Install third party stuff
notify_step "Installing third party packages"
while read -r package; do
    notify_substep "Installing third-party package: $package"
    sudo eopkg build -y --ignore-safety "$SPECS_RAW_URL/$package/pspec.xml"
    sudo eopkg install -y ./*.eopkg && rm -rfv ./*.eopkg
done < <(curl -sL "$LISTS_RAW_URL/solus/third_party.txt")
## Install extra applications and stuff
notify_step "Installing more packages"
sudo eopkg install -y caja-extensions sayonara-player libreoffice-all vscode hugo yadm fish hub git{,-extras} neofetch yarn golang solbuild{,-config{,-local}-unstable} font-firacode-otf
## Install development packages
notify_step "Installing development component"
sudo eopkg install -y -c system.devel
## Setup solbuild
notify_step "Setting up solbuild"
sudo solbuild init -u

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
while read -r repository; do
    notify_substep "Clonning repository: $repository"
    hub clone "$repository"
done < <(curl -sL "$LISTS_RAW_URL/common/git_repos.txt")
## Return to home
cd || exit

# Packaging
## Create packages folder
notify_step "Setting up Solus packages folder"
enter_folder "$PROJECT_DIR/Solus"
## Clone common repository
notify_step "Clonning common repository"
hub clone https://git.solus-project.com/common
## Link makefiles
notify_step "Linking makefiles"
ln -rsfv common/Makefile.toplevel Makefile
ln -rsfv common/Makefile.common   Makefile.common
ln -rsfv common/Makefile.iso      Makefile.iso
## Get source repositories
notify_step "Getting source repositories"
while read -r source; do
    notify_substep "Getting source: $repository"
    hub clone "https://git.solus-project.com/packages/$source"
done < <(curl -sL "$LISTS_RAW_URL/solus/package_sources.txt")
## Return to home
cd || exit

# Stremio
notify_step "Installing Stremio"
# shellcheck disable=SC2024
sudo bash < <(curl -sL "$SCRIPTS_RAW_URL/stremio.sh")

# Telegram Desktop
notify_step "Installing Telegram Desktop"
bash < <(curl -sL "$SCRIPTS_RAW_URL/tdesktop-alpha.sh")

# Go packages
notify_step "Installing Go packages"
## Create GOPATH so the Go packages installation will not do KABOOM!
export GOPATH="$PROJECT_DIR/Go"
## Install the Go package list
while read -r package; do
    notify_substep "Installing Go package: $package"
    go get -v -u "$package"
done < <(curl -sL "$LISTS_RAW_URL/common/go_packages.txt")

# System configuration files
notify_step "Adding system configuration files"
## Autologin
sudo mkdir -pv /etc/lightdm
echo -e "[Seat:*]\nautologin-user=$(whoami)" | sudo tee /etc/lightdm/lightdm.conf
## Stop fucking my CPU, solbuild
sudo mkdir -pv /etc/eopkg
echo -e "[build]\njobs = -j3" | sudo tee /etc/eopkg/eopkg.conf

# Password-less user (EXTREMELY INSANE STUFF)
notify_step "Setting password-less user"
## Remove user password
sudo passwd -du "$(whoami)"
## Add nullok option to Unix PAM module
sudo find /etc/pam.d/* -exec sed -i {} -e "s:shadow nullok:shadow:g" \
                                       -e "s:try_first_pass nullok:try_first_pass:g" \
                                       -e "s:pam_unix.so:pam_unix.so nullok:g" \;

# Finish
notify_step "Done, please reboot"
