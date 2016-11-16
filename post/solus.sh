#
# Solus: Post Install
# HERE BE DERGHUNS
#

# Variables
## Script name
SCRIPT_NAME="Solus: Post Install"
## Repositories
REPOSITORY_NAME="Solus"
UNSTABLE_URL="https://packages.solus-project.com/unstable/eopkg-index.xml.xz"
## 3rd-Party related
TRDPARTY_REPO="https://raw.githubusercontent.com/solus-project/3rd-party/master"
## Git-related
GIT_DIR="Git"
### My repositories
PERSONAL_GIT_URL="https://github.com/feskyde"
PERSONAL_GIT_REPOS=(blog
                    deezload
                    dotfiles
                    neogvim
                    pinstall
                    inscripts
                    wallpapers)
#### Directory names
REPO_BLOG="$GIT_DIR/blog"
REPO_DOTFILES="$GIT_DIR/dotfiles"
REPO_INSCRIPTS="$GIT_DIR/inscripts"
### Solus Git
SOLUS_GIT_URL="https://git.solus-project.com"
#### Directory names
SOLUS_GIT_DEST="$GIT_DIR/packages"
SOLUS_COMMON_DIR="$SOLUS_GIT_DEST/common"
### Setup scripts
INSCRIPTS_RUN=(zsh-antigen
               neovim-plug
               telegram-desktop)

# Functions
function notify_me() {
    # Usage: notify_me [message]
    # Print the [message] and send a notification
    message="$1"

    echo -e "\e[1m$SCRIPT_NAME: $message\e[0m"
    notify-send "$SCRIPT_NAME" "$message" -i distributor-logo-solus
}

function enter_dir() {
    # Usage: enter_dir [directory]
    # Enter into a [directory], if it doesn't
    # exists, create it
    directory="$1"

    if [ ! -d "$directory" ]; then
      mkdir -pv "$directory"
    fi
    cd "$directory" || exit
}

function tparty_get() {
    # Usage: tparty_get [component] [package]
    # Build and install a third-party package
    # with the given [component] and [package]
    component="$1"
    package="$2"

    sudo eopkg build -y --ignore-safety "$TRDPARTY_REPO/$component/$package/pspec.xml"
    sudo eopkg install -y "$package"*.eopkg
    sudo rm -rfv "$package"*.eopkg
}

function clone_list() {
    # Usage: clone_list [url] [list]
    # Clone every item on [list] using the Git
    # repositories from [url] as main url
    url="$1"
    list="$2"

    for repo in ${list[*]}; do
        git clone --recursive "$url"/"$repo"
    done
}

function run_setup() {
    # Usage: run_setup [script]
    # Run a setup [script]
    scripts="$1"

    for script in ${scripts[*]}; do
        bash ~/"$REPO_INSCRIPTS"/"$script".sh
    done
}

# Welcome
notify_me "$SCRIPT_NAME is running, don't touch anything now :)"

# Set-up needed directories
## LightDM and Arc-Paper variant
notify_me "Setting-up needed directories"
sudo mkdir -pv /etc/lightdm /usr/share/icons/Arc-Paper

# Password-less user
## Remove password for Casa
notify_me "Setting password-less user"
sudo passwd -du casa
## Add nullok option to PAM files
notify_me "Adding nullok option to PAM files (EXTREMELY INSANE STUFF)"
sudo sed -e "s/sha512 shadow try_first_pass nullok/sha512 shadow try_first_pass/g" -i /etc/pam.d/system-password
sudo sed -e "s/pam_unix.so/pam_unix.so nullok/g" -i /etc/pam.d/*
## Enable autologin
notify_me "Enabling autologin"
echo -e "[Seat:*]\nautologin-user=casa" | sudo tee /etc/lightdm/lightdm.conf

# Software stuff
## Remove ugly bloatware (Mozilla stuff), accesibility stuff and unused packages
notify_me "Removing unneded stuff"
sudo eopkg remove -y --purge thunderbird orca rhythmbox     \
                             tlp thermald doflicky yelp     \
                             rhythmbox-alternative-toolbar  \
                             {moka,faba{,-mono}}-icon-theme \
                             breeze{,-snow}-cursor-theme
### Move to unstable
notify_me "Moving to Unstable"
#### Remove Shannon
notify_me "Removing $REPOSITORY_NAME repository"
sudo eopkg remove-repo -y "$REPOSITORY_NAME"
#### Add Unstable
notify_me "Adding unstable repository"
sudo eopkg add-repo -y "$REPOSITORY_NAME" "$UNSTABLE_URL"
### Upgrade the system
notify_me "Upgrading system"
sudo eopkg upgrade -y
## Install other applications, fonts and some more thingies
notify_me "Installing more software"
sudo eopkg install -y paper-icon-theme budgie-{screenshot,haste}-applet geary     \
                      libreoffice-{writer,impress,calc,math,draw,base} gimp       \
                      simplescreenrecorder inkscape simple-scan brasero cheese    \
                      lollypop kodi neovim simplescreenrecorder zsh git{,-extras} \
                      nodejs neofetch p7zip glances {noto-sans,font-ubuntu}-ttf   \
                      flashplugin-nonfree

## Development component
notify_me "Installing development component"
sudo eopkg install -y -c system.devel
## Evobuild
notify_me "Setting up EvoBuild"
### Initialize
sudo evobuild -p unstable-x86_64 init
### Update
sudo evobuild -p unstable-x86_64 update
## Delete cache and clean
notify_me "Cleaning eopkg databases and cache"
### Delete cache
sudo eopkg delete-cache -y
### Clean databases
sudo eopkg clean -y

# Git clones
## Create dir and enter
notify_me "Creating Git directory"
enter_dir ~/"$GIT_DIR"
## Personal repositories
### Clone my repositories
notify_me "Cloning personal Git repositories"
clone_list "$PERSONAL_GIT_URL" "${PERSONAL_GIT_REPOS[*]}"
## Return to home
cd ~ || exit
## Solus packaging repository
### Create Solus packaging directory
notify_me "Setting up Solus packaging directory"
enter_dir ~/"$SOLUS_GIT_DEST"
### FUCKING CLONE common repository from Solus git
notify_me "Cloning common repository"
while true; do
  if [ ! -f "$SOLUS_COMMON_DIR"/Makefile.common ]; then
    if git clone "$SOLUS_GIT_URL"/common ~/"$SOLUS_COMMON_DIR"; then
      echo -e "YEAH IT WORKED!"
      break
    else
      echo -e "It failed! Retrying..."
    fi
  fi
done
### Link Makefile(s)
notify_me "Linking Makefiles"
ln -srfv ~/"$SOLUS_COMMON_DIR"/Makefile.common ~/"$SOLUS_GIT_DEST"/Makefile.common
ln -srfv ~/"$SOLUS_COMMON_DIR"/Makefile.toplevel ~/"$SOLUS_GIT_DEST"/Makefile
ln -srfv ~/"$SOLUS_COMMON_DIR"/Makefile.iso ~/"$SOLUS_GIT_DEST"/Makefile.iso
### Return to home
cd ~ || exit

# Dotfiles
## Set up dotfiles
notify_me "Installing dotfiles"
bash ~/"$REPO_DOTFILES"/install.sh
## Make ZSH default shell
notify_me "Making ZSH the default shell"
sudo chsh -s /bin/zsh casa

# Install scripts
## Run install scripts
notify_me "Running Install Scripts"
run_setup "${INSCRIPTS_RUN[*]}"

# Blog
## Install Hexo
notify_me "Installing Hexo"
sudo npm install hexo-cli -g
## Install dependencies
notify_me "Setting-up blog dependencies"
enter_dir ~/"$REPO_BLOG"
npm install
## Return to home
cd ~ || exit

# NeoVim
## Install plugins
notify_me "Installing NeoVim plugins"
nvim +PlugInstall +quitall

# Personalization
notify_me "Personalizing system"
## Create a theme index for Arc-Paper variant
notify_me "Setting up Arc-Paper variant"
sudo cp -Rfv /usr/share/icons/Arc/index.theme /usr/share/icons/Arc-Paper/index.theme
sudo sed -e "s/Inherits=Moka/Inherits=Paper/g" -i /usr/share/icons/Arc-Paper/index.theme
## Fix LightDM
notify_me "Fixing LightDM"
### Use Arc-Paper on LightDM GTK Greeter
echo -e "[greeter]\nicon-theme-name=Arc-Paper" | sudo tee /etc/lightdm/lightdm-gtk-greeter.conf
## Make GSettings set things
notify_me "Setting stuff with GSettings"
### Interface
gsettings set org.gnome.desktop.interface gtk-theme "Arc"
gsettings set org.gnome.desktop.interface icon-theme "Arc-Paper"
gsettings set org.gnome.desktop.interface cursor-theme "Paper"
### Privacy
gsettings set org.gnome.desktop.privacy remove-old-temp-files true
gsettings set org.gnome.desktop.privacy remove-old-trash-files true
### Location
gsettings set org.gnome.system.location enabled true
### Sounds
gsettings set org.gnome.desktop.sound event-sounds true
gsettings set org.gnome.desktop.sound input-feedback-sounds true
gsettings set org.gnome.desktop.sound theme-name "freedesktop"
### Screenshoter
gsettings set org.gnome.gnome-screenshot auto-save-directory "file:///home/casa/Im%C3%A1genes/Capturas"
### Terminal
gsettings set org.gnome.Terminal.Legacy.Settings theme-variant "dark"
gsettings set org.gnome.Terminal.Legacy.Settings new-terminal-mode "tab"

# FINISHED!
notify_me "Script finished! You SHOULD reboot now :)"
