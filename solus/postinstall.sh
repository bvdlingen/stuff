#!/usr/bin/env bash
#
# Solus Post Install Script (casa)
#

# Constants
THIS_USER="$(whoami)"
## RawGit files URL
RAW_FILES_URL="https://rawgit.com"
## Things repository URL
THINGS_REPO_URL="$RAW_FILES_URL/feddasch/things/master"
## Stuff lists
LISTS_FOLDER_URL="$THINGS_REPO_URL/lists"
## Installer scripts
SCRIPTS_FOLDER_URL="$THINGS_REPO_URL/scripts"
## Third Party package files
SPECS_RAW_URL="$RAW_FILES_URL/solus-project/3rd-party/master"
## Projects location
PROJECTS_DIR="$HOME/Proyectos"

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

# Switch to unstable repository
notify_step "Switching to Unstable repository"
sudo eopkg -y remove-repo Solus
sudo eopkg -y add-repo Solus https://packages.solus-project.com/unstable/eopkg-index.xml.xz

# Manage packages
## Remove unneded stuff
notify_step "Removing unneded stuff"
sudo eopkg -y remove --purge rhythmbox orca onboard
## Upgrade the system
notify_step "Getting the system up to date"
sudo eopkg -y upgrade
## Install third party stuff
notify_step "Installing third party packages"
while read -r package; do
    notify_substep "Installing third-party package: $package"
    sudo eopkg -y build --ignore-safety "$SPECS_RAW_URL/$package/pspec.xml"
    sudo eopkg -y install ./*.eopkg && rm -rfv ./*.eopkg
done < <(curl -sL "$LISTS_FOLDER_URL/solus/third_party.txt")
## Install extra applications and stuff
notify_step "Installing more packages"
sudo eopkg -y install caja-extensions sayonara-player libreoffice-all vscode yadm fish hub git{,-extras} neofetch golang yarn docker solbuild{,-config{,-local}-unstable} font-firacode-otf
## Install development packages
notify_step "Installing development component"
sudo eopkg -y install -c system.devel
## Setup solbuild
notify_step "Setting up solbuild"
sudo solbuild init -u

# Dotfiles
notify_step "Setting-up dotfiles"
yadm clone -f https://github.com/feddasch/dotfiles
yadm decrypt
## Link the VS Code stuff to VS Code OSS's
ln -rsfv "$HOME/.config/Code" "$HOME/.config/Code - OSS"
## Set fish as the default shell
sudo chsh -s "$(which fish)" "$THIS_USER"

# Git repositories
notify_step "Cloning Git repositories"
enter_folder "$PROJECTS_DIR"
## Clone the repositories
while read -r repository; do
    notify_substep "Clonning repository: $repository"
    hub clone "$repository"
done < <(curl -sL "$LISTS_FOLDER_URL/common/git_repos.txt")
## Return to home
cd || exit

# Packaging
notify_step "Setting up Solus packages folder"
enter_folder "$PROJECTS_DIR/Solus"
## Clone common repository
notify_step "Clonning common repository"
hub clone https://git.solus-project.com/common
## Link makefiles
notify_step "Linking makefiles"
ln -rsfv common/Makefile.common Makefile.common
ln -rsfv common/Makefile.iso Makefile.iso
ln -rsfv common/Makefile.toplevel Makefile
## Get source repositories
notify_step "Getting source repositories"
make clone -j100
## Return to home
cd || exit

# Stremio
notify_step "Installing Stremio"
# shellcheck disable=SC2024
sudo bash < <(curl -sL "$SCRIPTS_FOLDER_URL/stremio.sh")

# Telegram Desktop
notify_step "Installing Telegram Desktop"
bash < <(curl -sL "$SCRIPTS_FOLDER_URL/tdesktop-alpha.sh")

# Blog setup
notify_step "Setting up blog repository"
## Install Hexo
sudo yarn global add hexo-cli
## Install blog dependencies
enter_folder "$PROJECTS_DIR/blog"
yarn install

# Docker
## Enable it
sudo systemctl enable docker
## Add the user to the docker group
sudo usermod -aG docker "$THIS_USER"

# Go packages
notify_step "Installing Go packages"
## Create GOPATH so the Go packages installation will not do KABOOM!
export GOPATH="$PROJECTS_DIR/Go"
## Install the Go package list
while read -r package; do
    notify_substep "Installing Go package: $package"
    go get -v -u "$package"
done < <(curl -sL "$LISTS_FOLDER_URL/common/go_packages.txt")

# System configuration files
notify_step "Adding system configuration files"
## Autologin
sudo mkdir -pv /etc/lightdm
echo -e "[Seat:*]\nautologin-user=$THIS_USER" | sudo tee /etc/lightdm/lightdm.conf
## Stop fucking my CPU, solbuild
sudo mkdir -pv /etc/eopkg
echo -e "[build]\njobs = -j3" | sudo tee /etc/eopkg/eopkg.conf

# Password-less user (EXTREMELY INSANE STUFF)
notify_step "Setting password-less user"
## Remove user password
sudo passwd -du "$THIS_USER"
## Add nullok option to Unix PAM module
sudo find /etc/pam.d/* -exec sed -i {} -e "s:shadow nullok:shadow:g" \
                                       -e "s:try_first_pass nullok:try_first_pass:g" \
                                       -e "s:pam_unix.so:pam_unix.so nullok:g" \;

# Finish
notify_step "Done, please reboot"
