#!/usr/bin/env bash
#
# Stremio system-wide installation script
# Run this script as root!
#

# Variables (do not change!)
STREMIO_SRC="http://strem.io/download"
STREMIO_FILE="stremio.tar.gz"
STREMIO_SCRIPT="Stremio.sh"

# Options
STREMIO_DEST="/opt/stremio"
STREMIO_BINDEST="/usr/bin/stremio"

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

Tarball source : $STREMIO_SRC
Tarball dest   : $STREMIO_FILE
Script         : $STREMIO_SCRIPT
Destination    : $STREMIO_DEST
Binary link    : $STREMIO_BINDEST
"

# Enter into the Stremio folder
if ! test -d "$STREMIO_DEST"; then
    mkdir -pv "$STREMIO_DEST"
fi
cd "$STREMIO_DEST" || exit 1

# Download the tarball (if not exists) and extract
if ! test -f "$STREMIO_FILE"; then
    echo -e ">> Downloading the tarball"
    if ! wget "$STREMIO_SRC" -O "$STREMIO_FILE"; then
        echo -e "ERROR: Unable to download Stremio tarball"
        exit 1
    fi
fi
echo -e ">> Extracting the Stremio tarball"
if ! tar xfv "$STREMIO_FILE"; then
    echo -e "ERROR: Unable to extract Stremio file"
    exit 1
fi

# Link the script to $bindir (don't do this if DO_LINK=no was specified)
echo -e ">> Fixing the script"
if ! sed -e "s:\$(dirname \$0):$STREMIO_DEST:g" -i "$STREMIO_SCRIPT"; then
    echo -e "ERROR: Unable to fix the script, aren't you using GNU sed?"
    exit 1
fi
echo -e ">> Linking the script to $STREMIO_BINDEST"
if ! ln -rsfv "$STREMIO_SCRIPT" "$STREMIO_BINDEST"; then
    echo -e "ERROR: Unable to link the script to $STREMIO_BINDEST"
    exit 1
fi
