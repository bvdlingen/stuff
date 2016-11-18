#
# Dotfiles installer script
#

# Functions
## Syntax's syntax: function_name [argument] {optional argument} (optional flag)

function eprint() {
    # Syntax: eprint [order] [message]
    # Prints the [message] using [number]ed style
    number="$1"
    message="$2"
    if [ "$3" ]; then
        option="$3"
        if $option; then
            option="yes"
        else
            option="no"
        fi
    fi

    case "$number" in
        1) echo -e "\e[1m>\e[0m $message";;
        2) echo -e " \e[1m-\e[0m $message";;
        3) echo -e "  \e[1m·\e[0m $message $option";;
    esac
}

function remove_old() {
    # Syntax: remove_old [file]
    # Obviously it cleans the old [file]
    clean="$1"

    if [ -d ~/"$clean" ] || [ -f ~/"$clean" ]; then
        rm -rf ~/"$clean"
    fi
}

function check_dir() {
    # Syntax: check_dir [dir]
    # It check the [dir] directory
    check="$1"

    if [ ! -d ~/"$check" ]; then
        mkdir -p ~/"$check"
    fi
}

function link_file() {
    # Syntax: link_file [local] [dest]
    # Links [local] file to [dest]
    localf="$1"
    destf="$2"

    if [ ! -f ~/"$destf" ]; then
        ln -sf ~/"$MAINDIR"/"$localf" ~/"$destf"
    fi
}

function wipe_gpgdir() {
    # Syntax: wipe_gpgdir
    # Clean all GPG keys (wipes ~/.gnupg)

    if [ -d ~/.gnupg ]; then
        rm -rf ~/.gnupg
    fi
}

function import_gpg() {
    # Syntax: import_gpg [file] [type]
    # Import a GPG [file]
    file="$1"
    type="$2"

    if [ ! -f ~/"$MAINDIR"/"$file" ]; then
        eprint 1 "File $file doesn't exists, remove it from script :)"
    else
        eprint 1 "Importing $type key: $file"
        if [ "$type" == "private" ]; then
            gpg2 --allow-secret-key-import --import ~/"$MAINDIR"/"$file"
        elif [ "$type" == "public" ]; then
            gpg2 --import ~/"$MAINDIR"/"$file"
        else
            eprint 1 "Unknown key type!"
        fi
    fi
}

function dot_install() {
    # Syntax: dot_install [orig] [dest] {dir}
    # Links [orig] to [dest], if {dir} is specified,
    # the directory is created if necessary
    orig="$1"
    if [ "$3" ]; then
        folder="$2"
        dest="$2"/"$3"
    else
        dest="$2"
    fi

    if [ ! -f ~/"$MAINDIR"/"$orig" ]; then
        eprint 1 "File $orig doesn't exists, remove it from script :)"
    else
        eprint 1 "Linking file: $orig"
        check_dir "$folder"
        remove_old "$dest"
        link_file "$orig" "$dest"
    fi
}

function post_hook() {
    # Syntax: post_hook [executable] [command]
    # If [executable] exists, run the [command]
    executable="$1"
    command="$2"

    if which "$executable" &>/dev/null; then
        eprint 2 "Executable $executable found, running hook"
        bash -c "$command"
    else
        eprint 2 "Executable not found, not executing hook"
    fi
}


# Variables
## Set locations
DIR="Git"
REPO="home/dotfiles"
MAINDIR="$DIR/$REPO"
## Set default options
GIT=true
GPG=true
SOLUS=true
NVIM=true
ZSH=true

# Parse options
for option in "$@"; do
    case "$option" in
        --exclude-git)
            GIT=false
            shift
            ;;
        --exclude-gpg)
            GPG=false
            shift
            ;;
        --exclude-solus)
            SOLUS=false
            shift
            ;;
        --exclude-nvim)
            NVIM=false
            shift
            ;;
        --exclude-zsh)
            ZSH=false
            shift
            ;;
    esac
done

# Start
## Show options
eprint 3 "Git      " $GIT
eprint 3 "Solus    " $SOLUS
eprint 3 "NeoVIM   " $NVIM
eprint 3 "ZSH      " $ZSH

## Link files
if $GIT; then
    dot_install git/config.ini .gitconfig
fi

if $GPG; then
    wipe_gpgdir
    import_gpg gpg/private.asc private
    import_gpg gpg/public.asc public
fi

if $SOLUS; then
    dot_install solus/packager.ini .solus packager
fi

if $NVIM; then
    dot_install nvim/init.vim .config/nvim init.vim
    post_hook nvim "nvim +PlugInstall +qa"
fi

if $ZSH; then
    dot_install zsh/zshrc.sh .zshrc
fi
