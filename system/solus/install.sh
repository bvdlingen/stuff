# Variables
## Set locations
GITDIR="Git"
STARTREPO="start"
REPODIR="$STARTREPO/system/solus"
MAINDIR="$GITDIR/$REPODIR"
DIRECTORIES=(/etc/lightdm /usr/share/icons/Arc-Paper)

# Create necessary folders
for dir in ${DIRECTORIES[*]}; do
    if [ ! -d "$dir" ]; then
        sudo mkdir -pv "$dir"
    fi
done

# Copy files
sudo cp ~/"$MAINDIR"/lightdm/lightdm.conf /etc/lightdm/lightdm.conf
sudo cp ~/"$MAINDIR"/lightdm/greeter.conf /etc/lightdm/lightdm-gtk-greeter.conf
sudo cp ~/"$MAINDIR"/icons/Arc-Paper.theme /usr/share/icons/Arc-Paper
