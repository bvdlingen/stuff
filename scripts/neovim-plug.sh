#!/usr/bin/env bash
#
# Setup Scripts: Plug for NeoVim
#

# Variables
NVPLBIN="plug.vim"
NVPLURL="https://raw.githubusercontent.com/junegunn/vim-plug/master/$NVPLBIN"
NVPLDST=".config/nvim/autoload"

# Start
rm -rfv ~/"$NVPLDST"
mkdir -pv ~/"$NVPLDST"
wget "$NVPLURL" -O ~/"$NVPLDST"/"$NVPLBIN"

# Post hook
nvim +PlugInstall +qa
