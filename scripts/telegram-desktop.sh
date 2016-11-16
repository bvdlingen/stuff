#!/usr/bin/env bash
#
# Setup Scripts: Telegram Desktop
#

# Variables
TSRCZIP="linux"
TSRCURL="https://tdesktop.com/$TSRCZIP"
TSRCDIR="Telegram"
DESTDIR=".TelegramDesktop"

# Start
rm -rfv ~/"$DESTDIR"
mkdir -pv ~/"$DESTDIR"
wget "$TSRCURL" -O ~/"$DESTDIR"/"$TSRCZIP"
cd ~/"$DESTDIR" || exit
tar xfv "$TSRCZIP"
rm -rfv "$TSRCZIP"
echo -e "Executing..."
~/"$DESTDIR"/Telegram/Telegram 2>&1 >/dev/null
