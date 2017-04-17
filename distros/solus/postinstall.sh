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

# Functions
notify_step() {
    echo -e ">> $1"
    notify-send "Solus Post Install Script (casa)" "$1" -i distributor-logo-solus
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

list_tp_install() {
    while read -r package; do
        notify_substep "Installing third-party package: $package"
        sudo eopkg build -y --ignore-safety "$SPECS_RAW_URL/$package/pspec.xml"
        sudo eopkg install -y ./*.eopkg && rm -rfv ./*.eopkg
    done < <(curl -sL "$1")
}

# Welcome
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
sudo eopkg remove -y --purge firefox thunderbird arc-firefox-theme orca
## Upgrade the system
notify_step "Getting the system up to date"
sudo eopkg upgrade -y
## Install third party stuff
notify_step "Installing third party packages"
list_tp_install "$LISTS_RAW_URL/solus/third_party.txt"
## Install extra applications and stuff
notify_step "Installing more packages"
sudo eopkg install -y geary libreoffice-all vscode yadm fish neofetch git{,-extras} yarn golang heroku-cli \
                      solbuild{,-config{,-local}-unstable} font-firacode-otf budgie-{screenshot,haste}-applet

# User shell
notify_step "Setting $(which fish) as default user shell"
sudo chsh -s "$(which fish)" "$(whoami)"

# Stremio
notify_step "Installing Stremio"
# shellcheck disable=SC2024
sudo bash < <(curl -sL "$SCRIPTS_RAW_URL/stremio.sh")

# Password-less user (EXTREMELY INSANE STUFF)
notify_step "Setting password-less user"
## Remove user password
sudo passwd -du "$(whoami)"
## Add nullok option to PAM files
sudo find /etc/pam.d -name "*" -exec sed -i {} -e "s:try_first_pass nullok:try_first_pass:g" \
                                               -e "s:pam_unix.so:pam_unix.so nullok:g" \;
