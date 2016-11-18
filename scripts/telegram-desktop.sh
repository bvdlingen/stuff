#!/usr/bin/env bash
#
# Setup Scripts: Telegram Desktop
#

# Variables
TSRCZIP="linux"
TSRCURL="https://tdesktop.com/$TSRCZIP"
DESTDIR=".TelegramDesktop"

# Start
rm -rfv ~/"$DESTDIR"
mkdir -pv ~/"$DESTDIR"
wget "$TSRCURL" -O ~/"$DESTDIR"/"$TSRCZIP"
cd ~/"$DESTDIR" || exit
tar xfv "$TSRCZIP"
rm -rfv "$TSRCZIP"
echo -e "Executing..."
~/"$DESTDIR"/"$TSRCDIR"/Telegram >/dev/null 2>&1
