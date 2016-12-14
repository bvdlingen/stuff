#!/usr/bin/env bash
#
# System files installer
#

# Variables
## Set locations
FILES_DIR="$HOME/Git/stuff/system"

# Copy files
sudo install -Dm644 "$FILES_DIR/lightdm/lightdm.conf" /etc/lightdm/lightdm.conf
sudo install -Dm644 "$FILES_DIR/lightdm/greeter.conf" /etc/lightdm/lightdm-gtk-greeter.conf
sudo install -Dm644 "$FILES_DIR/themes/default.cursor" /usr/share/icons/default/index.theme
