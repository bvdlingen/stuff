#
# Solus Post Install Script
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
PERSONAL_GIT_REPOS=(start
                    deezload
                    kydebot
                    nekovim
                    olimpia)
#### Directory names
REPO_BLOG="$GIT_DIR/blog"
REPO_START="$GIT_DIR/start"
DOTFILES_DIR="$REPO_START/dotfiles"
SCRIPTS_DIR="$REPO_START/scripts"
SYSTEM_DIR="$REPO_START/system/solus"
### Solus Git
SOLUS_GIT_URL="https://git.solus-project.com"
#### Directory names
SOLUS_GIT_DEST="$GIT_DIR/packages"
SOLUS_COMMON_DIR="$SOLUS_GIT_DEST/common"

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

    sudo eopkg build -y --ignore-safety "$TRDPARTY_REPO"/"$component"/"$package"/pspec.xml
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
        bash ~/"$SCRIPTS_DIR"/"$script".sh
    done
}

# Welcome
notify_me "$SCRIPT_NAME is running, don't touch anything now :)"

# Password-less user
## Remove password for Casa
notify_me "Setting password-less user"
sudo passwd -du casa
## Add nullok option to PAM files
notify_me "Adding nullok option to PAM files (EXTREMELY INSANE STUFF)"
sudo sed -e "s/sha512 shadow try_first_pass nullok/sha512 shadow try_first_pass/g" -i /etc/pam.d/system-password
sudo sed -e "s/pam_unix.so/pam_unix.so nullok/g" -i /etc/pam.d/*

# Software stuff
## Remove ugly bloatware (Mozilla stuff), accesibility stuff and unused packages
notify_me "Removing unneded stuff"
sudo eopkg remove -y --purge firefox arc-firefox-theme thunderbird rhythmbox               \
                             tlp thermald doflicky yelp orca rhythmbox-alternative-toolbar \
                             {moka,faba{,-mono}}-icon-theme breeze{,-snow}-cursor-theme
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
## Install 3rd-party applications
notify_me "Installing Third Party applications"
tparty_get network/web/browser google-chrome-stable          # SANER WEB BROWSER, TAKE THIS, MOZILLA!
tparty_get multimedia/music spotify                          # I DON'T USE THIS, BUT FAMILY IS FAMILY
tparty_get desktop/font mscorefonts                          # OH, THE UGLY MICROSOFT FONTS :S
## Install other applications, fonts and some more thingies
notify_me "Installing more software"
sudo eopkg install -y paper-icon-theme budgie-{screenshot,haste}-applet geary kodi  \
                      libreoffice-{writer,impress,calc,math,draw,base} gimp cheese  \
                      simplescreenrecorder inkscape simple-scan brasero lollypop    \
                      neovim zsh git{,-extras} hub nodejs neofetch p7zip glances    \
                      {noto-sans,font-ubuntu}-ttf
## Development component
notify_me "Installing development component"
sudo eopkg install -y -c system.devel
## Evobuild
notify_me "Setting up EvoBuild"
### Initialize
sudo evobuild -p unstable-x86_64 init
### Update
sudo evobuild -p unstable-x86_64 update

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
bash ~/"$DOTFILES_DIR"/install.sh
## Make ZSH default shell
notify_me "Making ZSH the default shell"
sudo chsh -s /bin/zsh casa

# Deploy system
## Install system files
notify_me "Installing system files"
bash ~/"$SYSTEM_DIR"/install.sh

# Install Telegram Desktop
## Run installer
notify_me "Installing Telegram Desktop"
bash ~/"$SCRIPTS_DIR"/telegram-desktop.sh

# Personalization
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
