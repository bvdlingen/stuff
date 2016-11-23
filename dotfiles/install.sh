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

function wipe_if_exists() {
    # Syntax: wipe_if_exists [file]
    # Obviously it cleans the old [file]
    clean="$1"

    if [ -d ~/"$clean" ] || [ -f ~/"$clean" ]; then
        rm -rf ~/"$clean"
    fi
}

function check_directory() {
    # Syntax: check_directory [dir]
    # It check the [dir] directory
    check="$1"

    if [ ! -d ~/"$check" ]; then
        mkdir -p ~/"$check"
    fi
}

function do_file_link() {
    # Syntax: do_file_link [local] [dest]
    # Links [local] file to [dest]
    localf="$1"
    destf="$2"

    if [ ! -f ~/"$destf" ]; then
        ln -sf ~/"$MAINDIR"/"$localf" ~/"$destf"
    fi
}

function post_hook() {
    # Syntax: post_hook [hook] [var1] [var2]
    hook="$1"
    var1="$2"
    var2="$3"

    case "$hook" in
        run_command)
            executable="$var1"
            command="$var2"

            if ! hash "$executable" > /dev/null 2>&1; then
                eprint 2 "Executable not found, not executing hook"
            else
                eprint 2 "Executable $executable found, running hook"
                bash -c "$command"
            fi
            ;;

        run_script)
            file="$var1"
            script="$var2"

            if [ ! -f ~/"$file" ]; then
                eprint 2 "File not found, executing hook"
                bash ~/"$SCRIPTSDIR"/"$script".sh
            else
                eprint 2 "File found, not executing hook"
            fi
            ;;
    esac
}

function dotinstall() {
    # Syntax: dotinstall [orig] [dest] {dir}
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
        check_directory "$folder"
        wipe_if_exists "$dest"
        do_file_link "$orig" "$dest"
    fi
}

# Variables
## Set locations
STARTREPO="Git/start"
MAINDIR="$STARTREPO/dotfiles"
SCRIPTSDIR="$STARTREPO/scripts"
## Set default options
GIT=true
SOLUS=true
NEOVIM=true
ZSHELL=true

# Parse options
for option in "$@"; do
    case "$option" in
        --exclude-git)
            GIT=false
            shift
            ;;
        --exclude-solus)
            SOLUS=false
            shift
            ;;
        --exclude-nvim)
            NEOVIM=false
            shift
            ;;
        --exclude-zsh)
            ZSHELL=false
            shift
            ;;
    esac
done

# Start
## Show options
eprint 3 "Git      " $GIT
eprint 3 "Solus    " $SOLUS
eprint 3 "NeoVim   " $NEOVIM
eprint 3 "Z Shell  " $ZSHELL

## Link files
if $GIT; then
    dotinstall git/config.ini .gitconfig
fi

if $SOLUS; then
    dotinstall solus/packager.ini .solus packager
fi

if $NEOVIM; then
    dotinstall nvim/init.vim .config/nvim init.vim
    post_hook run_script .config/nvim/autoload/plug.vim neovim-plug
    post_hook run_command nvim "nvim +PlugInstall +qa"
fi

if $ZSHELL; then
    dotinstall zsh/zshrc.sh .zshrc
    post_hook run_script .antigen/antigen.zsh zsh-antigen
fi
