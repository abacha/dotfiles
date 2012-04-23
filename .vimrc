set nocompatible
let mapleader=","

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" ENCODING
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
set encoding=utf-8
set fileencoding=utf-8

runtime bundle/tpope_vim-pathogen/autoload/pathogen.vim
call pathogen#infect()

let g:netrw_home="~/.vim/backup"

" Open vimrc with <leader>v
nmap <leader>v :tabedit $MYVIMRC<CR>

let g:indent_guides_auto_colors=1
let g:indent_guides_enable_on_vim_startup=0
let g:indent_guides_color_change_percent=3
let g:indent_guides_guide_size=0
noremap <leader>i :IndentGuidesToggle<CR>

if &t_Co > 2 || has("gui_running")
  syntax enable
  set hlsearch
  nmap <silent> <leader>h :silent :nohlsearch<CR>
endif

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" COLORS
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
set t_Co=256
set background=dark
colorscheme solarized
let g:solarized_contrast="low"

filetype on
filetype plugin on
filetype indent on

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" ARROW KEYS ARE UNACCEPTABLE
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
map <Left> :echo "no!"<cr>
map <Right> :echo "no!"<cr>
map <Up> :echo "no!"<cr>
map <Down> :echo "no!"<cr>

set relativenumber
set tabstop=2
set shiftwidth=2
set softtabstop=2
set expandtab
set smarttab
set backspace=indent,eol,start
set listchars=tab:▸\ ,eol:¬,trail:·,precedes:«,extends:»
set textwidth=80
set linebreak
set showbreak=…
set sidescroll=5
set scrolloff=5
set formatprg=par\ -TbgqRw80
set autoindent
set smartindent
set ignorecase
set smartcase
set incsearch
set showmatch
set matchtime=2
set ruler
set number
set autoread
set wildmenu
set wildmode=list:longest
set shortmess=atI
set timeoutlen=500
set wrap
set wrapmargin=80
set visualbell
set hidden
set title
set cc=+1

command! -nargs=* Wrap set wrap linebreak nolist
set backupdir=~/.vim/backup,~/tmp,/var/tmp,/tmp
set directory=~/.vim/backup,~/tmp,/var/tmp,/tmp

" Use c-s to save current file
nnoremap <silent> <C-S> :if expand("%") == ""<CR>browse confirm w<CR>else<CR>confirm w<CR>endif<CR>

cnoremap %% <C-R>=expand("%:h")."/"<CR>

set completeopt=menu,menuone,longest
set pumheight=10

set wildignore+=*/.hg/*,*/.svn/*
set wildignore+=*.o,moc_*.cpp,*.exe,*.qm
set wildignore+=.gitkeep,.DS_Store

" Hash rocket with <c-l>
imap <c-l> <space>=><space>

" Ruby exec current file with <leader> w
nmap <leader>w :w<cr>\|:!ruby %<cr>

" Copy with <C-C>
vmap <C-C> "*y
nmap <leader>r :exec &nu==0 ? "set number" : "set relativenumber"<cr>

" Paste toggle with <leader>p
set pastetoggle=<leader>p

" Trail whitespaces
command! Trail execute "%s/ *$//g"

" Switch buffers with <leader>ea
map <leader>ea :b#<CR>

" Save/quit typos
cab W w| cab Q q| cab Wq wq| cab wQ wq| cab WQ wq

autocmd CursorHold * checktime
" Exit insert mode with "jj"
imap jj <esc>

" Keep line index when reopening a file
autocmd BufReadPost *
  \ if line("'\"") > 0 && line("'\"") <= line("$") |
  \   exe "normal g`\"" |
  \ endif

" Move around splits with <c-hjkl>
nnoremap <c-j> <c-w>j
nnoremap <c-k> <c-w>k
nnoremap <c-h> <c-w>h
nnoremap <c-l> <c-w>l

" Split screen using \ for vertical and - for horizontal
map <C-W>\ :vsp<CR>
map <C-W>- :sp<CR>

map <leader>l :set list!<CR>
" set winwidth=84
" set winheight=10
" set winminheight=10
" set winheight=999

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" PLUGINS
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

" Open buffer with <C-B>
nmap <C-B> :CtrlPBuffer<cr>
" Ignore git files on CtrlP
let g:ctrlp_custom_ignore='\.git$'

" Gist plugin
let g:gist_open_browser_after_post = 1
let g:gist_detect_filetype = 1
let g:gist_clip_command = 'xclip -selection clipboard'
let g:github_token = '141ac5143d7fc424a203f514e10dc40d'
