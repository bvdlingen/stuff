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
## Don't require a leading dot for matching 'hidden' files
setopt globdots
## Let the user edit the command line after history expansion
setopt histverify
## Show an error if no matches are found on globbing
setopt nomatch
## No beep on error
setopt nobeep
## Notify
setopt notify
## Ignore duplicates on auto_pushd
setopt pushdignoredups
## Allow short loop forms
setopt shortloops

# Settings
## Completion
### Name groups during completion
zstyle ':completion:*' group-name ''
zstyle ':completion:*:matches' group 'yes'
zstyle ':completion:*:options' description 'yes'
zstyle ':completion:*:options' auto-description '%d'
zstyle ':completion:*:descriptions' format $'\e[1;32m -- %d --\e[0m'
zstyle ':completion:*:messages' format $'\e[1;32m -- %d --\e[0m'
zstyle ':completion:*:warnings' format $'\e[1;32m -- No Matches Found --\e[0m'
### Fuzzy matching of completions for when mistyped
zstyle ':completion:*' completer _complete _match _approximate
zstyle ':completion:*:match:*' original only
zstyle ':completion:*:approximate:*' max-errors 'reply=( $(( ($#PREFIX + $#SUFFIX) / 3 )) )'
zstyle ':completion::approximate*:*' prefix-needed false
### If using a directory as argument, remove the trailing slash
zstyle ':completion:*' squeeze-slashes true
### Ignore completion functions for unexistent commands
zstyle ':completion:*:functions' ignored-patterns '_*'
### Completing process IDs with menu selection
zstyle ':completion:*:*:kill:*' menu yes select
zstyle ':completion:*:kill:*' force-list always
### Better-ize manual handling
zstyle ':completion:*:manuals' separate-sections true
zstyle ':completion:*:manuals.(^1*)' insert-sections true

# History
## Set file path
HISTFILE=~/.zhistory
## Set ammount of commands will be saved
HISTSIZE=1000
SAVEHIST=1000
## Ignore duplicates and lines starting with spaces
HISTCONTROL=ignoreboth

# Functions
## Manage a lot of Git repositories
function regit() {
    # Syntax: regit [command]
    # Recursively manage Git repositories under a directory

    command="$1"
    for dir in $(ls); do
        if [ -d "$dir"/.git ]; then
            echo -e "In repository: $dir"
            cd "$dir"
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
                git commit -s -m "Forced recursive push"
                git push
                ;;
        esac
        cd ..
    done
}

# Aliases
## Solus packaging aliases
alias yauto='../common/Scripts/yauto.py'
alias yconvert='../common/Scripts/yconvert.py'
alias ybump='/usr/share/ypkg/ybump.py'
alias yupdate='/usr/share/ypkg/yupdate.py'
## Extra aliases
alias xopen='xdg-open'
alias weather='curl wttr.in/Ezeiza'

# Variables
## Editor and visual editor
export EDITOR="nvim"
export VISUAL="nvim"
export BROWSER="google-chrome-stable"

# Antigen
## Load the script
source ~/.antigen/antigen.zsh
## Load the oh-my-zsh's repo
antigen use oh-my-zsh
## Bundles
### Bundles from oh-my-zsh's repo
antigen bundle colored-man-pages
antigen bundle command-not-found
antigen bundle git
antigen bundle lol
antigen bundle nyan
antigen bundle sublime
antigen bundle zsh_reload
antigen bundle web-search
### ZSH Users' bundles
antigen bundle zsh-users/zsh-completions
antigen bundle zsh-users/zsh-history-substring-search
antigen bundle zsh-users/zsh-syntax-highlighting
### Autoupdate bundle
antigen bundle unixorn/autoupdate-antigen.zshplugin
### Bash-compatibility bundle
antigen bundle chrissicool/zsh-bash
## Theme
antigen theme fishy
## Apply changes
antigen apply
## Extra
### Binding keys for history-substring-search
bindkey '^[[A' history-substring-search-up
bindkey '^[[B' history-substring-search-down
