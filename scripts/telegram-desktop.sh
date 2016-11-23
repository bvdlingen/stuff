#!/usr/bin/env bash
#
# Setup Scripts: Telegram Desktop
#

# Variables
TSRCZIP="current?alpha=1"
TSRCURL="https://tdesktop.com/linux/$TSRCZIP"
DESTDIR=".TelegramDesktop"
TDSTZIP="telegram-alpha.tar.xz"

# Start
rm -rfv ~/"$DESTDIR"
mkdir -pv ~/"$DESTDIR"
wget "$TSRCURL" -O ~/"$DESTDIR"/"$TDSTZIP"
cd ~/"$DESTDIR" || exit
tar xfv "$TDSTZIP"
rm -rfv "$TDSTZIP"
