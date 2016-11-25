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
### My repositories
PERSONAL_GIT_URL="https://github.com/feskyde"
PERSONAL_GIT_REPOS=(stuff
                    deezloader
                    kydebot
                    nekovim)
#### Directory names
GIT_DIR="Git"
STUFF_REPO="$GIT_DIR/stuff"
SCRIPTS_DIR="$STUFF_REPO/scripts"
SYSTEM_DIR="$STUFF_REPO/distro/solus/system"
### Solus Git
SOLUS_GIT_URL="https://git.solus-project.com"
#### Directory names
SOLUS_PACKAGES_DIR="$GIT_DIR/packages"
SOLUS_COMMON_DIR="$SOLUS_PACKAGES_DIR/common"
## YADM-related
DOTFILES_REPO="$PERSONAL_GIT_URL/dotfiles"
## Install Scripts
SCRIPTS_RUN=(zsh-antigen
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
## Remove unneed packages
notify_me "Removing unneded stuff"
sudo eopkg remove -y --purge orca {moka,faba{,-mono}}-icon-theme
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
## Install more applications and stuff
sudo eopkg install -y paper-icon-theme budgie-{screenshot,haste}-applet kodi cheese    \
                      brasero obs-studio gimp inkscape libreoffice-all neovim          \
                      zsh git{,-extras} hub yadm glances neofetch flash-player-nonfree
## Development component
notify_me "Installing development component"
sudo eopkg install -y -c system.devel
## Evobuild
notify_me "Setting up EvoBuild"
### Initialize
sudo evobuild -p unstable-x86_64 init
### Update
sudo evobuild -p unstable-x86_64 update

# Git repositories
## Create directory and enter
notify_me "Creating Git directory"
enter_dir ~/"$GIT_DIR"
## Personal repositories
### Clone my repositories
notify_me "Cloning personal Git repositories"
clone_list "$PERSONAL_GIT_URL" "${PERSONAL_GIT_REPOS[*]}"
## Return to home
cd ~ || exit

# Solus packaging repository
## Create Solus packaging directory
notify_me "Setting up Solus packaging directory"
enter_dir ~/"$SOLUS_PACKAGES_DIR"
## FUCKING CLONE common repository from Solus
notify_me "Cloning common repository"
while true; do
  if [ ! -f "$SOLUS_COMMON_DIR"/Makefile.common ]; then
    if git clone "$SOLUS_GIT_URL"/common ~/"$SOLUS_COMMON_DIR"; then
      notify_me "YEAH IT WORKED!"
      break
    else
      notify_me "It failed! Retrying..."
    fi
  fi
done
## Link Makefile(s)
notify_me "Linking Makefiles"
ln -srfv ~/"$SOLUS_COMMON_DIR"/Makefile.common ~/"$SOLUS_PACKAGES_DIR"/Makefile.common
ln -srfv ~/"$SOLUS_COMMON_DIR"/Makefile.toplevel ~/"$SOLUS_PACKAGES_DIR"/Makefile
ln -srfv ~/"$SOLUS_COMMON_DIR"/Makefile.iso ~/"$SOLUS_PACKAGES_DIR"/Makefile.iso
## Return to home
cd ~ || exit

# Dotfiles
## Set up dotfiles
notify_me "Setting-up dotfiles"
### Clone the repository
yadm clone "$DOTFILES_REPO"
### Decrypt files
yadm decrypt
## Set ZSH as default shell
notify_me "Set ZSH as default shell"
sudo chsh -s $(which zsh) casa

# Install scripts
## Run install scripts
notify_me "Running Install Scripts"
run_setup "${SCRIPTS_RUN[*]}"

# Stupidly deployable system
## Install system files
notify_me "Installing system files"
bash ~/"$SYSTEM_DIR"/install.sh

# Development libraries
## Python
### Install libraries
#### Via Python Package index
notify_me "Installing Python development libraries via PyPI"
sudo pip3 install neovim python-telegram-bot
#### Via eopkg
notify_me "Installing Python development libraries via eopkg"
sudo eopkg install -y python3-gobject-devel

# Personalization
## Make GSettings set things
notify_me "Setting stuff with GSettings"
### Interface
gsettings set org.gnome.desktop.interface icon-theme "Arc-Paper"
### Privacy
gsettings set org.gnome.desktop.privacy remove-old-temp-files true
gsettings set org.gnome.desktop.privacy remove-old-trash-files true
### Location
gsettings set org.gnome.system.location enabled true
### Sounds
gsettings set org.gnome.desktop.sound event-sounds true
gsettings set org.gnome.desktop.sound input-feedback-sounds true
gsettings set org.gnome.desktop.sound theme-name "freedesktop"
### Terminal
gsettings set org.gnome.Terminal.Legacy.Settings theme-variant "dark"
gsettings set org.gnome.Terminal.Legacy.Settings new-terminal-mode "tab"

# FINISHED!
notify_me "Script finished! You SHOULD reboot now :)"
