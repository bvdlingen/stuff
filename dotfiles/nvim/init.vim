" Plugins
"" Initialize Plug
call plug#begin('~/.config/nvim/plugins')
"" Add the plugins
""" Look and feel
Plug 'sonph/onehalf', {'rtp': 'vim/'}  " OneDark-like color scheme
Plug 'vim-airline/vim-airline'         " Da fecking Airline
""" Tools
Plug 'tpope/vim-fugitive'              " Best Git wrapper ever
Plug 'airblade/vim-gitgutter'          " Git gutters
Plug 'scrooloose/nerdtree'             " The NerdTree thingy
Plug 'raimondi/delimitmate'            " Automagically close brackets
Plug 'ap/vim-css-color'                " Colorize text (hex code/names)
Plug 'pbrisbin/vim-mkdir'              " Create directories if necessary
Plug 'junegunn/vim-easy-align'         " Fast tabulation on multiple lines
Plug 'kien/rainbow_parentheses.vim'    " Color matching parentheses
Plug 'terryma/vim-multiple-cursors'    " Sublime-like multiple word select
Plug 'tpope/vim-endwise'               " Ends certain structures automatically
""" Languages
Plug 'davidhalter/jedi-vim'            " Jedi for Python
Plug 'fisadev/vim-isort'               " Sort python imports (:Isort or V-Block + ctrl+i)
""" Syntax
Plug 'sheerun/vim-polyglot'            " Polyglot highlighting
Plug 'scrooloose/syntastic'            " External syntax checkers
""" Completions
Plug 'Shougo/deoplete.nvim'            " Deoplete completion system
Plug 'ervandew/supertab'               " Sublime-like completion for text already on file
""" Extra
Plug 'mhinz/vim-startify'              " Start page for Vim
"" End Plug
call plug#end()

" Configuration
"" Color scheme
""" Configure and enable
"""" Force a 256 color range
set t_Co=256
"""" Activate italics, they're pretty
let g:onedark_terminal_italics = 1
"" Airline
""" Set theme
let g:airline_theme='onehalfdark'
""" Transparent background
hi Normal ctermbg=none
""" Use Deoplete
let deoplete#enable_at_startup = 1
set completeopt=menuone,noinsert,noselect
let g:deoplete#enable_refresh_always = 1
""" Jedi config changes
let g:jedi#use_splits_not_buffers = "left"
let g:jedi#popup_on_dot = 0
let g:jedi#show_call_signatures = 2
let g:jedi#auto_vim_configuration = 0
"" Set shell
set shell=/bin/zsh
"" Disable backups and swapfile
set nobackup
set nowritebackup
set noswapfile
"" Get rid of NeoVim's mode indicator
set noshowmode
"" Open new split panes to right and bottom, which feels more natural
set splitbelow
set splitright
"" Always use vertical diffs
set diffopt+=vertical
"" Show line numbers
set number
set numberwidth=5
"" Highlight current line
set cursorline
"" Indentation
set tabstop=4
set shiftwidth=4
set softtabstop=4
set expandtab
"" Use true colors
set termguicolors
"" Color scheme
colorscheme onehalfdark

" Keybindings
"" Plugins
""" NerdTree
"""" Toggle the NerdTree
map <C-t> :NERDTreeToggle<CR>
"" Tab completion
set wildmode=list:longest,list:full
function! InsertTabWrapper()
    let col = col('.') - 1
    if !col || getline('.')[col - 1] !~ '\k'
        return "\<tab>"
    else
        return "\<c-p>"
    endif
endfunction
inoremap <Tab> <c-r>=InsertTabWrapper()<cr>
inoremap <S-Tab> <c-n>
"" Remapping vim autocompletion keys to ctrl-space
inoremap <C-@> <C-x><C-o>
"" Change between buffers shortcut
nnoremap <silent> [b :bprevious<cr>
nnoremap <silent> ]b :bnext<cr>

" Autocmds
"" Remove trailing whitespaces
autocmd BufWritePre * %s/\s\+$//e
"" Rainbow Parentheses always on
autocmd VimEnter * RainbowParenthesesToggle
autocmd Syntax * RainbowParenthesesLoadRound
autocmd Syntax * RainbowParenthesesLoadSquare
autocmd Syntax * RainbowParenthesesLoadBraces
