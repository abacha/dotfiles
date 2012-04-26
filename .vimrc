set nocompatible
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" ENCODING
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
set encoding=utf-8
set fileencoding=utf-8

let mapleader=","
runtime bundle/tpope_vim-pathogen/autoload/pathogen.vim
call pathogen#infect()

let g:netrw_home="~/.vim/backup"

" Open vimrc with <leader>v
nmap <leader>v :tabedit $MYVIMRC<CR>
nmap <leader>sv :source $MYVIMRC<cr>

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
" FOLDING
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
set foldmethod=indent
set foldnestmax=10
set nofoldenable
set foldlevel=1

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" COLORS
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
set t_Co=256
set background=dark
colorscheme solarized
"let g:solarized_contrast="low"

filetype on
filetype plugin on
filetype indent on

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" UNBIND KEYS
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
nnoremap <Left> <nop>
nnoremap <Right> <nop>
nnoremap <Up> <nop>
nnoremap <Down> <nop>
inoremap <esc> <nop>

" Tab spacing/sice
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

" Screen offset
set sidescroll=8
set scrolloff=8

set formatprg=par\ -TbgqRw80
set autoindent
set smartindent
set ignorecase
set smartcase
set incsearch
set showmatch
set matchtime=2
set ruler
set number "show line number
set autoread
set wildmenu
set wildmode=list:longest
set shortmess=atI
set timeoutlen=500
set wrap
set wrapmargin=80
set visualbell "no crazy beeping
set hidden
set title
set cc=+1

command! -nargs=* Wrap set wrap linebreak nolist
set backupdir=~/.vim/backup,~/tmp,/var/tmp,/tmp
set directory=~/.vim/backup,~/tmp,/var/tmp,/tmp

" Use c-s to save current file
nnoremap <silent> <C-S> :if expand("%") == ""<CR>browse confirm w<CR>else<CR>confirm w<CR>endif<CR><CR>

cnoremap %% <C-R>=expand("%:h")."/"<CR>

set completeopt=menu,menuone,longest
set pumheight=10

set wildignore+=*/.hg/*,*/.svn/*
set wildignore+=*.o,moc_*.cpp,*.exe,*.qm
set wildignore+=.gitkeep,.DS_Store

" Hash rocket with <C-l>
imap <C-l> <space>=><space>

" Ruby exec current file with <leader> w
nmap <leader>w :w<cr>\|:!ruby %<cr>

" Copy with <C-C>
vmap <C-C> "*y

" Toggle absolute/relative line number
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

" Exit insert mode with jj
inoremap jj <esc>

" Keep line index when reopening a file
autocmd BufReadPost *
  \ if line("'\"") > 0 && line("'\"") <= line("$") |
  \   exe "normal g`\"" |
  \ endif

" Split screen using \ for vertical and - for horizontal
noremap <C-\> :vsp<CR>
noremap <C--> :sp<CR>

" Move around splits with <C-hjkl>
noremap <C-j> <C-w>j
noremap <C-k> <C-w>k
noremap <C-h> <C-w>h
noremap <C-l> <C-w>l
noremap <C-q> <C-w>q


" Folding
nnoremap <space> za

" Sudo to write
cnoremap w!! w !sudo tee % >/dev/null

" Toggle invisible characters
map <leader>l :set list!<CR>

" set winwidth=84
" set winheight=10
" set winminheight=10
" set winheight=999

" Surround word with separators
nnoremap <leader>" viw<esc>a"<esc>hbi"<esc>lel
nnoremap <leader>' viw<esc>a'<esc>hbi'<esc>lel
nnoremap <leader>( viw<esc>a(<esc>hbi)<esc>lel
nnoremap <leader>[ viw<esc>a[<esc>hbi]<esc>lel

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
let g:github_token = $GITHUB_TOKEN
