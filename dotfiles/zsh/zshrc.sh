# Shell options
## Always move to the end of a word when completting
setopt alwaystoend
## Create the file when redirection (>>) is used
setopt appendcreate
## Automatic run cd if only a directory is given
setopt autocd
## Automatically append dirs to the push/pop list
setopt autopushd
## Enable ! history expansion
setopt banghist
## Enable globbing using braces
setopt braceccl
## cd-able variables
setopt cdablevars
## Don't expand aliases before completion has finished
setopt completealiases
## If unset the cursor is set to the end of the word if completion is started
setopt completeinword
## Automatically correct the spelling of each word on the command line
setopt correctall
## The mighty =command expansion; try: print =vim (if you've vim installed)
setopt equals
## Extended globbing
setopt extendedglob
## Save additional info to $HISTFILE
setopt extendedhistory
## Cycle through globbing matches like menu_complete
setopt globcomplete
## Don't require a leading dot for matching "hidden" files
setopt globdots
## Let the user edit the command line after history expansion
setopt histverify
## Ignore duplicates on history
setopt histignorealldups
## Show an error if no matches are found on globbing
setopt nomatch
## No beep on error
setopt nobeep
## Erase errors when globbing
unsetopt nomatch
## Notify
setopt notify
## Ignore duplicates on auto_pushd
setopt pushdignoredups
## Not idea of what this does
setopt pushdminus
## Silent pushd
setopt pushdsilent
## pushd to $HOME
setopt pushdtohome
## Allow short loop forms
setopt shortloops

# Settings
## Completion
### Name groups during completion
zstyle ":completion:*" group-name ""
zstyle ":completion:*:matches" group "yes"
zstyle ":completion:*:options" description "yes"
zstyle ":completion:*:options" auto-description "%d"
zstyle ":completion:*:descriptions" format $"\e[1;32m -- %d --\e[0m"
zstyle ":completion:*:messages" format $"\e[1;32m -- %d --\e[0m"
zstyle ":completion:*:warnings" format $"\e[1;32m -- No Matches Found --\e[0m"
### Fuzzy matching of completions for when mishashd
zstyle ":completion:*" completer _complete _match _approximate
zstyle ":completion:*:match:*" original only
zstyle ":completion:*:approximate:*" max-errors "reply=( $(( ($#PREFIX + $#SUFFIX) / 3 )) )"
zstyle ":completion::approximate*:*" prefix-needed false
### If using a directory as argument, remove the trailing slash
zstyle ":completion:*" squeeze-slashes true
### Ignore completion functions for unexistent commands
zstyle ":completion:*:functions" ignored-patterns "_*"
### Completing process IDs with menu selection
zstyle ":completion:*:*:kill:*" menu yes select
zstyle ":completion:*:kill:*" force-list always
### Better-ize manual handling
zstyle ":completion:*:manuals" separate-sections true
zstyle ":completion:*:manuals.(^1*)" insert-sections true

# Profiles
## Default compiler flags
if [ -z "${CFLAGS}" ]; then
    export CFLAGS="-mtune=generic -march=x86-64 -ftree-vectorize -g2 -O2 -pipe -fPIC -Wformat -Wformat-security -fno-omit-frame-pointer -fstack-protector-strong --param ssp-buffer-size=4 -fexceptions -D_FORTIFY_SOURCE=2 -feliminate-unused-debug-hashs -Wno-error -Wp,-D_REENTRANT"
fi

if [ -z "${CXXFLAGS}" ]; then
    export CXXFLAGS="-mtune=generic -march=x86-64 -ftree-vectorize -g2 -O2 -pipe -fPIC -Wformat -Wformat-security -fno-omit-frame-pointer -fstack-protector-strong --param ssp-buffer-size=4 -fexceptions -D_FORTIFY_SOURCE=2 -feliminate-unused-debug-hashs -Wno-error -Wp,-D_REENTRANT"
fi

if [ -z "${LDFLAGS}" ]; then
    export LDFLAGS="-Wl,--copy-dt-needed-entries -Wl,-O1 -Wl,-z,relro -Wl,-z,now"
fi

if [ -z "${FCFLAGS}" ]; then
    export FCFLAGS="${CFLAGS}"
fi

if [ -z "${FFLAGS}" ]; then
    export FFLAGS="${CFLAGS}"
fi

# Functions
## Manage a lot of Git repositories
function regit() {
    # Syntax: regit [command]
    # Recursively manage Git repositories under a directory

    command="$1"
    for dir in *; do
        if [ -d "$dir" ] && [ -d "$dir"/.git ]; then
            echo -e "In repository: $dir"
            cd "$dir" || exit
        else
            continue
        fi
        case "$command" in
            status)
                git status
                ;;
            pull)
                git pull
                ;;
            commit)
                git add .
                git scommit -m "Forced recursive push"
                git push
                ;;
        esac
        cd ..
    done
}

# Aliases
## Solus packaging aliases
if hash ypkg > /dev/null 2>&1; then
    alias yauto="../common/Scripts/yauto.py"
    alias yconvert="../common/Scripts/yconvert.py"
    alias ybump="/usr/share/ypkg/ybump.py"
    alias yupdate="/usr/share/ypkg/yupdate.py"
fi
## Alias hub to git if exists (better usage)
if hash hub > /dev/null 2>&1; then
    alias git="hub"
fi
## Extra aliases
alias xopen="xdg-open"
alias weather="curl wttr.in/Ezeiza"

# Variables
## Applications
### Editor and visual editor
export EDITOR="nvim"
export VISUAL="$EDITOR"
### Web browser
export BROWSER="google-chrome-stable"
## pushd/popd stack
export DIRSTACKSIZE=5
## History
### File path
export HISTFILE=~/.zhistory
### Ammount of commands will be saved
export HISTSIZE=1000
export SAVEHIST=1000

# Antigen
## Set variables
export ANTIHOME=$HOME/.antigen
## Load the script
# shellcheck source=/dev/null
source "$ANTIHOME"/antigen.zsh
## Load the oh-my-zsh's repo
antigen use oh-my-zsh
## Bundles
### Bundles from oh-my-zsh
antigen bundle colored-man-pages
antigen bundle command-not-found
antigen bundle nyan
antigen bundle zsh_reload
antigen bundle web-search
### ZSH Users" bundles
antigen bundle zsh-users/zsh-completions
antigen bundle zsh-users/zsh-history-substring-search
antigen bundle zsh-users/zsh-syntax-highlighting
## Theme
antigen theme fishy
## Apply changes
antigen apply
## Extra
### Binding keys for history-substring-search
bindkey "^[[A" history-substring-search-up
bindkey "^[[B" history-substring-search-down

# Neofetch
## Run it with disabled packages
neofetch --disable packages
