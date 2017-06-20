#!/usr/bin/env bash
#
# Stremio system-wide installation script
# Run this script as root!
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
STREMIO_FILES_DEST="/usr/share/stremio"
STREMIO_BINARY_DEST="/usr/bin/stremio"
STREMIO_SHARED_DEST="/usr/share"

# Constants (do not change!)
STREMIO_TARBALL_SOURCE="http://strem.io/download"
STREMIO_TARBALL="stremio.tar.gz"
STREMIO_BINARY="Stremio.sh"
STREMIO_DESKTOP_SOURCE="https://rawgit.com/feddasch/stuff/master/scripts/files/stremio.desktop"
STREMIO_DESKTOP_DEST="$STREMIO_SHARED_DEST/applications/stremio.desktop"

# Check if we meet all requeriments
printstep "Checking requeriments"
## Are we an admin user?
if ! test "$EUID" -eq 0; then
    erroexit "You need to have administrator privileges to run this script"
fi
## Is wget installed?
bintype wget
## If we're in Solus, install the libidn dependency
if type eopkg; then
    if ! sudo eopkg install -y libidn; then
        erroexit "Unable to install libidn dependency"
    fi
fi

# Print a autotools-like big wall of text with all the options
echo -e "
>> Here we go!

Tarball source : $STREMIO_TARBALL_SOURCE
Tarball name   : $STREMIO_TARBALL
Script         : $STREMIO_BINARY
Destination    : $STREMIO_FILES_DEST
Binary link    : $STREMIO_BINARY_DEST
.desktop dest  : $STREMIO_DESKTOP_DEST
"

# Enter into the Stremio folder
if ! test -d "$STREMIO_FILES_DEST"; then
    mkdir -pv "$STREMIO_FILES_DEST"
fi
cd "$STREMIO_FILES_DEST" || erroexit "Cannot enter into Stremio folder"

# Download the tarball (if not exists), extract and remove
if ! test -f "$STREMIO_TARBALL"; then
    printstep "Downloading the tarball"
    if ! wget -nv --show-progress "$STREMIO_TARBALL_SOURCE" -O "$STREMIO_TARBALL"; then
        rm -rfv "$STREMIO_TARBALL"
        erroexit "Unable to download Stremio tarball"
    fi
fi
printstep "Extracting the Stremio tarball"
if ! tar xf "$STREMIO_TARBALL"; then
    erroexit "Unable to extract Stremio file"
fi
printstep "Removing the downloaded file"
if ! rm -rfv "$STREMIO_TARBALL"; then
    erroexit "Unable to remove the downloaded file"
fi

# Link the script to $bindir (don't do this if DO_LINK=no was specified)
printstep "Fixing the script"
if ! sed -e "s:\$(dirname \$0):$STREMIO_FILES_DEST:g" -i "$STREMIO_BINARY"; then
    erroexit "Unable to fix the script, aren't you using GNU sed?"
fi
printstep "Linking the script to $STREMIO_BINARY_DEST"
if ! ln -rsfv "$STREMIO_BINARY" "$STREMIO_BINARY_DEST"; then
    erroexit "Unable to link the script to $STREMIO_BINARY_DEST"
fi

# Add a .desktop file
printstep "Adding a .desktop file"
if ! wget -nv --show-progress "$STREMIO_DESKTOP_SOURCE" -O "$STREMIO_DESKTOP_DEST"; then
    erroexit "Unable to add a .desktop file"
fi
