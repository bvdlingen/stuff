#!/usr/bin/env bash
#
# Solus Post Install Script (casa)
#

# Constants
## RawGit files URL
RAW_FILES_URL="https://rawgit.com"
## Things repository URL
STUFF_REPO_URL="$RAW_FILES_URL/feddasch/stuff/master"
## Lists
LISTS_FOLDER_URL="$STUFF_REPO_URL/lists"
## Installer scripts
SCRIPTS_FOLDER_URL="$STUFF_REPO_URL/install"
## Third Party package files
SPECS_RAW_URL="$RAW_FILES_URL/solus-project/3rd-party/master"
## Projects location
PROJECTS_DIR="$HOME/Proyectos"

# Functions
function newstep() {
    echo -e "STEP> $1"
    notify-send "Solus Post Install Script (casa)" "$1" -i distributor-logo-solus
}

function newsubstep() {
    echo -e "STEP - $1"
}

function changedir() {
    if ! test -d "$1"; then
        newsubstep "Creating folder: $1"
        mkdir -pv "$1"
    fi

    newsubstep "Entering to folder: $1"
    cd "$1" || exit
}

# Switch to unstable repository
newstep "Switching to Unstable repository"
sudo eopkg -y remove-repo Solus
sudo eopkg -y add-repo Solus https://packages.solus-project.com/unstable/eopkg-index.xml.xz

# Manage packages
## Remove unneded stuff
newstep "Removing unneded stuff"
sudo eopkg -y remove --purge firefox arc-firefox-theme thunderbird rhythmbox{,-alternative-toolbar} orca
## Upgrade the system
newstep "Getting the system up to date"
sudo eopkg -y upgrade
## Install third party stuff
newstep "Installing third party packages"
while read -r package; do
    newsubstep "Installing third-party package: $package"
    sudo eopkg -y build --ignore-safety "$SPECS_RAW_URL/$package/pspec.xml"
    sudo eopkg -y install ./*.eopkg && rm -rfv ./*.eopkg
done < <(curl -sL "$LISTS_FOLDER_URL/solus/third_party.txt")
## Install extra applications and stuff
newstep "Installing more packages"
sudo eopkg -y install budgie-{haste,screenshot}-applet sayonara-player libreoffice-all vscode hugo fish \
                      yadm hub git-extras golang yarn docker solbuild-config{,-local}-unstable neofetch
## Install development packages
newstep "Installing development component"
sudo eopkg -y install -c system.devel
## Setup solbuild
newstep "Setting up solbuild"
sudo solbuild init -u

# Dotfiles
newstep "Setting-up dotfiles"
yadm clone -f https://github.com/feddasch/dotfiles
yadm decrypt
## Link the vscode config folder to VS Code OSS' folder
ln -rsfv "$HOME/.config/vscode" "$HOME/.config/Code - OSS"
## Set fish as the default shell
sudo chsh -s "$(which fish)" "$(whoami)"

# Git repositories
newstep "Cloning Git repositories"
changedir "$PROJECTS_DIR"
## Clone the repositories
while read -r repository; do
    newsubstep "Clonning repository: $repository"
    hub clone --recursive "$repository"
done < <(curl -sL "$LISTS_FOLDER_URL/common/git_repos.txt")
## Return to home
cd || exit

# Packaging
newstep "Setting up Solus packages folder"
changedir "$PROJECTS_DIR/Solus"
## Clone common repository
newstep "Clonning common repository"
hub clone --recursive --depth=1 https://dev.solus-project.com/source/common
## Link makefiles
newstep "Linking makefiles"
ln -rsfv common/Makefile.common Makefile.common
ln -rsfv common/Makefile.iso Makefile.iso
ln -rsfv common/Makefile.toplevel Makefile
## Get source repositories
newstep "Getting source repositories"
make clone -j100
## Return to home
cd || exit

# Stremio
newstep "Installing Stremio"
sudo bash < <(curl -sL "$SCRIPTS_FOLDER_URL/stremio/install.sh")

# Telegram Desktop
newstep "Installing Telegram Desktop"
bash < <(curl -sL "$SCRIPTS_FOLDER_URL/telegramdesktop/install.sh")

# Docker
## Enable it
sudo systemctl enable docker
## Add the user to the docker group
sudo usermod -aG docker "$(whoami)"

# Go packages
newstep "Installing Go packages"
## Create GOPATH so the Go packages installation will not do KABOOM!
export GOPATH="$PROJECTS_DIR/Go"
## Install the Go package list
while read -r package; do
    newsubstep "Installing Go package: $package"
    go get -v -u "$package"
done < <(curl -sL "$LISTS_FOLDER_URL/common/go_packages.txt")

# System configuration files
newstep "Adding system configuration files"
## Autologin
sudo mkdir -pv /etc/lightdm
echo -e "[Seat:*]\nautologin-user=$(whoami)" | sudo tee /etc/lightdm/lightdm.conf
## Stop fucking my CPU, solbuild
sudo mkdir -pv /etc/eopkg
echo -e "[build]\njobs = -j3" | sudo tee /etc/eopkg/eopkg.conf

# Password-less user (EXTREMELY INSANE STUFF)
newstep "Setting password-less user"
## Remove user password
sudo passwd -du "$(whoami)"
## Add nullok option to Unix PAM module
sudo find /etc/pam.d/* -exec sed -i {} -e "s:shadow nullok:shadow:g" \
                                       -e "s:try_first_pass nullok:try_first_pass:g" \
                                       -e "s:pam_unix.so:pam_unix.so nullok:g" \;
