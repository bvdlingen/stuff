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
## Telegram Desktop
TDESKTOP_URL="https://tdesktop.com/linux/current?alpha=1"
TDESKTOP_TARBALL="tdesktop.tar.gz"

# Functions
function cddir() {
    if ! test -d "$1"; then
        if ! mkdir -p "$1"; then
            exit
        fi
    fi

    cd "$1" || exit
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
    sudo eopkg -y install ./*.eopkg && rm -rf ./*.eopkg
done
## Install extra packages
sudo eopkg -y install budgie-{haste,screenshot}-applet sayonara-player libreoffice-all retroarch \
                      vscode yadm fish git{,-extras} hub golang yarn heroku-cli docker neofetch
## Install development component and solbuild configs
sudo eopkg -y install -c system.devel cve-check-tool solbuild-config{,-local}-unstable
## Setup solbuild build image
sudo solbuild init -u

# Dotfiles
## Clone the repository and decrypt the protected files
yadm clone -f https://github.com/feddasch/dotfiles
yadm decrypt
## Link the VS Code config to the OSS' folder
ln -rsfv "$HOME/.config/Code" "$HOME/.config/Code - OSS"
## Set fish as the default shell
sudo chsh -s "$(which fish)" "$(whoami)"

# Git repositories
cddir "$PROJECT_DIR"
## Clone the stuff repository
hub clone stuff
## Clone the repositories
while ISC="" read -r repository || [[ -n "$repository" ]]; do
    hub clone "$repository"
done < "$STUFF_REPO_DIR/lists/git/repos.txt"
## Return to the home directory
cd || exit

# Solus packaging
cddir "$PROJECT_DIR/Solus"
## Clone common repository
hub clone https://dev.solus-project.com/source/common
## Link Makefiles from common
ln -rsfv common/Makefile.toplevel Makefile
ln -rsfv common/Makefile.common Makefile.common
ln -rsfv common/Makefile.iso Makefile.iso
## Get sources
make clone -j100
## Return to the home directory
cd || exit

# Telegram Desktop
## Install it
cddir "$HOME/.TelegramDesktop"
wget "$TDESKTOP_URL" -O "$TDESKTOP_TARBALL"
tar xf "$TDESKTOP_TARBALL" --strip-components=1
rm -rf "$TDESKTOP_TARBALL"
## Put the .desktop file where it belongs
cddir "$HOME/.local/share/applications"
cp -rf "$STUFF_REPO_DIR/files/tdesktop/tdesktop.desktop" telegramdesktop.desktop
sed -e "s:%HOME%:$HOME:g" -i telegramdesktop.desktop
### Return to the home directory
cd || exit

# Docker
## Enable the service
sudo systemctl enable docker
## Add the user to the docker group
sudo usermod -aG docker "$(whoami)"

# Go packages
export GOPATH="$PROJECT_DIR/Go"
## Install the Go installable packages
while ISC="" read -r package || [[ -n "$package" ]]; do
    go get -u "$package"
done < "$STUFF_REPO_DIR/lists/golang/install.txt"
## Download the Go downloadable packages
while ISC="" read -r package || [[ -n "$package" ]]; do
    go get -u -d "$package"
done < "$STUFF_REPO_DIR/lists/golang/download.txt"

# Additional system configuration files
## Enable autologin for this user
sudo mkdir -p /etc/lightdm
echo -e "[Seat:*]\nautologin-user=$(whoami)" | sudo tee /etc/lightdm/lightdm.conf
## solbuild eats my CPUs, avoid that
sudo mkdir -p /etc/eopkg
echo -e "[build]\njobs = -j3" | sudo tee /etc/eopkg/eopkg.conf

# Personalization
## Privacy
gsettings set org.gnome.desktop.privacy remove-old-temp-files true
gsettings set org.gnome.desktop.privacy remove-old-trash-files true
## Location
gsettings set org.gnome.system.location enabled true
## Sounds
gsettings set org.gnome.desktop.sound event-sounds true
gsettings set org.gnome.desktop.sound input-feedback-sounds true
gsettings set org.gnome.desktop.sound theme-name "freedesktop"
## Window manager
gsettings set org.gnome.desktop.wm.preferences num-workspaces 1

# Reboot
systemctl reboot
