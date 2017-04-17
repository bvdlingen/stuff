#!/usr/bin/env bash
#
# Stremio system-wide installation script
# Run this script as root!
#

# Options
STREMIO_FILES_DEST="/opt/stremio"
STREMIO_BINARY_DEST="/usr/bin/stremio"
STREMIO_SHARED_DEST="/usr/share"

# Variables (do not change!)
STREMIO_TARBALL_SOURCE="http://strem.io/download"
STREMIO_TARBALL="stremio.tar.gz"
STREMIO_BINARY="Stremio.sh"
STREMIO_DESKTOP_SOURCE="https://raw.githubusercontent.com/feddasch/things/master/scripts/files/stremio.desktop"
STREMIO_DESKTOP_DEST="$STREMIO_SHARED_DEST/applications/stremio.desktop"

# Check if we meet all requeriments
echo -e ">> Checking requeriments"
## Are we an admin user?
if ! test "$EUID" -eq 0; then
    echo -e "ERROR: You need to have administrator privileges to run this script"
    exit 1
else
    echo -e "Admin account detected"
fi
## Is wget installed?
if ! type wget; then
    echo -e "ERROR: You need wget to be installed before using this script"
    exit 1
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
cd "$STREMIO_FILES_DEST" || exit 1

# Download the tarball (if not exists), extract and remove
if ! test -f "$STREMIO_TARBALL"; then
    echo -e ">> Downloading the tarball"
    if ! wget -nv --show-progress "$STREMIO_TARBALL_SOURCE" -O "$STREMIO_TARBALL"; then
        echo -e "ERROR: Unable to download Stremio tarball"
        rm -rfv "$STREMIO_TARBALL"
        exit 1
    fi
fi
echo -e ">> Extracting the Stremio tarball"
if ! tar xf "$STREMIO_TARBALL"; then
    echo -e "ERROR: Unable to extract Stremio file"
    exit 1
fi
echo -e ">> Removing the downloaded file"
if ! rm -rfv "$STREMIO_TARBALL"; then
    echo -e "ERROR: Unable to remove the downloaded file"
    exit 1
fi

# Link the script to $bindir (don't do this if DO_LINK=no was specified)
echo -e ">> Fixing the script"
if ! sed -e "s:\$(dirname \$0):$STREMIO_FILES_DEST:g" -i "$STREMIO_BINARY"; then
    echo -e "ERROR: Unable to fix the script, aren't you using GNU sed?"
    exit 1
fi
echo -e ">> Linking the script to $STREMIO_BINARY_DEST"
if ! ln -rsfv "$STREMIO_BINARY" "$STREMIO_BINARY_DEST"; then
    echo -e "ERROR: Unable to link the script to $STREMIO_BINARY_DEST"
    exit 1
fi

# Add a .desktop file
echo -e ">> Adding a .desktop file"
if ! wget -nv --show-progress "$STREMIO_DESKTOP_SOURCE" -O "$STREMIO_DESKTOP_DEST"; then
    echo -e "ERROR: Unable to add a .desktop file"
    exit 1
fi
