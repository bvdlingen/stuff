#!/usr/bin/env bash
#
# Telegram Desktop user installation script
#

# Functions
function printstep() {
    echo -e "STEP> $1"
}

function erroexit() {
    echo -e "ERRO> $1"
    exit 1
}

function bintype() {
    if ! type "$1"; then
        erroexit "$1 not found"
    fi
}

# Options
TDESKTOP_FILES_DEST="$HOME/.TelegramDesktop"

# Constants (do not change!)
TDESKTOP_TARBALL_SOURCE="https://tdesktop.com/linux/current"
TDESKTOP_TARBALL="tdesktop.tar.gz"
TDESKTOP_DESKTOP_SOURCE="https://rawgit.com/feddasch/stuff/master/installer/telegramdesktop/files/telegramdesktop.desktop"
TDESKTOP_DESKTOP_DEST_FOLDER="$HOME/.local/share/applications"
TDESKTOP_DESKTOP_DEST="$TDESKTOP_DESKTOP_DEST_FOLDER/telegramdesktop.desktop"

# Check if we meet all requeriments
printstep "Checking requeriments"
## Is wget installed?
bintype wget

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
cd "$TDESKTOP_FILES_DEST" || erroexit "Cannot enter into Telegram Desktop folder"

# Download the tarball (if not exists), extract and remove
if ! test -f "$TDESKTOP_TARBALL"; then
    printstep "Downloading the tarball"
    if ! wget -nv --show-progress "$TDESKTOP_TARBALL_SOURCE" -O "$TDESKTOP_TARBALL"; then
        rm -rfv "$TDESKTOP_TARBALL"
        erroexit "Unable to download Telegram Desktop tarball"
    fi
fi
printstep "Extracting the Telegram Desktop tarball"
if ! tar xf "$TDESKTOP_TARBALL" --strip-components=1; then
    erroexit "Unable to extract Telegram Desktop file"
fi
printstep "Removing the downloaded file"
if ! rm -rfv "$TDESKTOP_TARBALL"; then
    erroexit "Unable to remove the downloaded file"
fi

# Add a .desktop file
printstep "Adding a .desktop file"
if ! test -d "$TDESKTOP_DESKTOP_DEST_FOLDER"; then
    mkdir -pv "$TDESKTOP_DESKTOP_DEST_FOLDER"
fi
if ! wget -nv --show-progress "$TDESKTOP_DESKTOP_SOURCE" -O "$TDESKTOP_DESKTOP_DEST"; then
    erroexit "Unable to add a .desktop file"
fi
if ! sed -e "s:%EXECUTABLE%:$TDESKTOP_FILES_DEST/Telegram:g" -i "$TDESKTOP_DESKTOP_DEST"; then
    erroexit "Unable to fix .desktop file"
fi
