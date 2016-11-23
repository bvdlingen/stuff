# Variables
## Set locations
GITDIR="Git/stuff"
REPODIR="distro/solus/system"
MAINDIR="$GITDIR/$REPODIR"
DIRECTORIES=(/etc/lightdm /usr/share/icons/default /usr/share/icons/Arc-Paper)

# Create necessary folders
for dir in ${DIRECTORIES[*]}; do
    if [ ! -d "$dir" ]; then
        sudo mkdir -pv "$dir"
    fi
done

# Copy files
sudo cp ~/"$MAINDIR"/lightdm/lightdm.conf /etc/lightdm/lightdm.conf
sudo cp ~/"$MAINDIR"/lightdm/greeter.conf /etc/lightdm/lightdm-gtk-greeter.conf
sudo cp ~/"$MAINDIR"/themes/default.cursor /usr/share/icons/default/index.theme
sudo cp ~/"$MAINDIR"/themes/arc-paper.icons /usr/share/icons/Arc-Paper/index.theme
