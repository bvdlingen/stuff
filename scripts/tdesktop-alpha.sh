#!/usr/bin/env bash
#
# Telegram Desktop (Alpha) user installation script
#

# Options
TDESKTOP_FILES_DEST="$HOME/.TelegramDesktop"

# Variables (do not change!)
TDESKTOP_TARBALL_SOURCE="https://tdesktop.com/linux/current?alpha=1"
TDESKTOP_TARBALL="tdesktop-alpha.tar.gz"
TDESKTOP_DESKTOP_SOURCE="https://raw.githubusercontent.com/feddasch/things/master/scripts/files/telegramdesktop.desktop"
TDESKTOP_DESKTOP_DEST_FOLDER="$HOME/.local/share/applications"
TDESKTOP_DESKTOP_DEST="$TDESKTOP_DESKTOP_DEST_FOLDER/telegramdesktop.desktop"

# Check if we meet all requeriments
echo -e ">> Checking requeriments"
## Is wget installed?
if ! type wget; then
    echo -e "ERROR: You need wget to be installed before using this script"
    exit 1
fi

# Print a autotools-like big wall of text with all the options
echo -e "
>> Here we go!

Tarball source : $TDESKTOP_TARBALL_SOURCE
Tarball name   : $TDESKTOP_TARBALL
Destination    : $TDESKTOP_FILES_DEST
.desktop dest  : $TDESKTOP_DESKTOP_DEST
"

# Enter into the Telegram Desktop folder
if ! test -d "$TDESKTOP_FILES_DEST"; then
    mkdir -pv "$TDESKTOP_FILES_DEST"
fi
cd "$TDESKTOP_FILES_DEST" || exit 1

# Download the tarball (if not exists), extract and remove
if ! test -f "$TDESKTOP_TARBALL"; then
    echo -e ">> Downloading the tarball"
    if ! wget -nv --show-progress "$TDESKTOP_TARBALL_SOURCE" -O "$TDESKTOP_TARBALL"; then
        echo -e "ERROR: Unable to download Telegram Desktop tarball"
        rm -rfv "$TDESKTOP_TARBALL"
        exit 1
    fi
fi
echo -e ">> Extracting the Telegram Desktop tarball"
if ! tar xf "$TDESKTOP_TARBALL" --strip-components=1; then
    echo -e "ERROR: Unable to extract Telegram Desktop file"
    exit 1
fi
echo -e ">> Removing the downloaded file"
if ! rm -rfv "$TDESKTOP_TARBALL"; then
    echo -e "ERROR: Unable to remove the downloaded file"
    exit 1
fi

# Add a .desktop file
echo -e ">> Adding a .desktop file"
if ! test -d "$TDESKTOP_DESKTOP_DEST_FOLDER"; then
    mkdir -pv "$TDESKTOP_DESKTOP_DEST_FOLDER"
fi
if ! wget -nv --show-progress "$TDESKTOP_DESKTOP_SOURCE" -O "$TDESKTOP_DESKTOP_DEST"; then
    echo -e "ERROR: Unable to add a .desktop file"
    exit 1
fi
if ! sed -e "s:%EXECUTABLE%:$TDESKTOP_FILES_DEST/Telegram:g" -i "$TDESKTOP_DESKTOP_DEST"; then
    echo -e "ERROR: Unable to fix .desktop file"
    exit 1
fi
