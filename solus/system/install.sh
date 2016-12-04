#!/usr/bin/env bash
#
# System files installer
#

# Variables
## Set locations
GITDIR="Git/stuff"
REPODIR="solus/system"
MAINDIR="$GITDIR/$REPODIR"
DIRECTORIES=(/etc/lightdm /usr/share/icons/default)

# Create necessary folders
for dir in ${DIRECTORIES[*]}; do
    if [ ! -d "$dir" ]; then
        sudo mkdir -pv "$dir"
    fi
done

# Copy files
sudo cp "$HOME/$MAINDIR/lightdm/lightdm.conf" /etc/lightdm/lightdm.conf
sudo cp "$HOME/$MAINDIR/lightdm/greeter.conf" /etc/lightdm/lightdm-gtk-greeter.conf
sudo cp "$HOME/$MAINDIR/themes/default.cursor" /usr/share/icons/default/index.theme
