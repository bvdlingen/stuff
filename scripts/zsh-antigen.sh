#!/usr/bin/env bash
#
# Setup Scripts: tmux Package Manager
#

# Variables
ATGROOT=".antigen"
ATGGIT="https://github.com/zsh-users/antigen"
ATGBRANCH="develop"

# Start
rm -rfv ~/"$ATGROOT"
mkdir -pv ~/"$ATGROOT"
git clone --depth=1 "$ATGGIT" -b "$ATGBRANCH" ~/"$ATGROOT"
