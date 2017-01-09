#!/usr/bin/env bash
#
# Stateless configuration files installer
#

# Variables
## File's location
CONFIGS_DIR="$HOME/Git/stuff/config"

# Install files
## LightDM
sudo install -Dm644 "$CONFIGS_DIR/lightdm/lightdm.conf" /etc/lightdm/lightdm.conf
