#!/usr/bin/env bash
#
# Solus Post Install Script
#

# Constants
## Third Party package files
THIRD_PARTY_URL="https://rawgit.com/solus-project/3rd-party/master"
## Project directory location
PROJECT_DIR="$HOME/Proyectos"
## Stuff repository location
STUFF_REPO_DIR="$PROJECT_DIR/stuff"

# Functions
function pushdir() {
    if ! test -d "$1"; then
        if ! mkdir -pv "$1"; then
            exit
        fi
    fi

    pushd "$1" || exit
}

# Repositories
## Switch to unstable repository
sudo eopkg -y remove-repo Solus
sudo eopkg -y add-repo Solus https://packages.solus-project.com/unstable/eopkg-index.xml.xz

# Packages
## Remove unwanted packages
sudo eopkg -y remove --purge firefox arc-firefox-theme thunderbird rhythmbox{,-alternative-toolbar} orca
## Upgrade the whole system
sudo eopkg -y upgrade
## Install third-party packages
for package in "desktop/font/mscorefonts" "network/web/browser/google-chrome-stable"; do
    sudo eopkg -y build --ignore-safety "$THIRD_PARTY_URL/$package/pspec.xml"
    sudo eopkg -y install ./*.eopkg && rm -rfv ./*.eopkg
done
## Install extra packages
sudo eopkg -y install budgie-{haste,screenshot}-applet sayonara-player libreoffice-all vscode steam retroarch \
                      fish yadm hub git-extras golang yarn docker solbuild-config{,-local}-unstable neofetch
## Install development component
sudo eopkg -y install -c system.devel
## Setup solbuild build image
sudo solbuild init -u

# Dotfiles
## Clone the repository and decrypt the protected files
yadm clone -f https://github.com/feddasch/dotfiles
yadm decrypt
## Link the VS Code config to the OSS' folder
ln -rsfv "$HOME/.config/vscode" "$HOME/.config/Code - OSS"
## Set fish as the default shell
sudo chsh -s "$(which fish)" "$(whoami)"

# Git repositories
pushdir "$PROJECT_DIR"
## Clone the stuff repository
hub clone stuff
## Clone the repositories
while ISC="" read -r repository || [[ -n "$repository" ]]; do
    hub clone "$repository"
done < "$STUFF_REPO_DIR/lists/git_repositories.txt"
## Return to the home directory
popd || exit

# Solus packaging
pushdir "$PROJECT_DIR/Solus"
## Clone common repository
hub clone --depth=1 https://dev.solus-project.com/source/common
## Link Makefiles from common
ln -rsfv common/Makefile.common Makefile.common
ln -rsfv common/Makefile.iso Makefile.iso
ln -rsfv common/Makefile.toplevel Makefile
## Get sources
make clone -j100
## Return to the home directory
popd || exit

# Telegram Desktop
bash "$STUFF_REPO_DIR/install/tdesktop/install.sh"

# Docker
## Enable it
sudo systemctl enable docker
## Add the user to the docker group
sudo usermod -aG docker "$(whoami)"

# Go packages
## Create GOPATH so the Go packages installation will not do KABOOM!
export GOPATH="$PROJECT_DIR/Go"
## Install the Go installable packages
while ISC="" read -r package || [[ -n "$package" ]]; do
    go get -v -u "$package"
done < "$STUFF_REPO_DIR/lists/golang/install.txt"
## Download the Go downloadable packages
while ISC="" read -r package || [[ -n "$package" ]]; do
    go get -v -u -d "$package"
done < "$STUFF_REPO_DIR/lists/golang/download.txt"

# Additional system configuration files
## solbuild eats my CPUs, do not allow it
sudo mkdir -pv /etc/eopkg
echo -e "[build]\njobs = -j3" | sudo tee /etc/eopkg/eopkg.conf
