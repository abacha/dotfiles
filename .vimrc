set nocompatible "use vim defaults
filetype off

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" ENCODING
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
set encoding=utf-8
set fileencoding=utf-8

let mapleader=","

" let Vundle manage Vundle
set rtp+=~/.vim/bundle/Vundle.vim
call vundle#begin()
Plugin 'VundleVim/Vundle.vim'

" Bundles
Plugin 'altercation/vim-colors-solarized'
Plugin 'kchmck/vim-coffee-script'
Plugin 'abacha/ctrlp.vim'                   " fuzzy finder
Plugin 'mattn/gist-vim'
Plugin 'mattn/webapi-vim'
Plugin 'leafgarland/typescript-vim'
Plugin 'tpope/vim-commentary'               " comment gcc
Plugin 'tpope/vim-endwise'
Plugin 'tpope/vim-fugitive'                 " git helpers
Plugin 'tpope/vim-haml'
Plugin 'tpope/vim-rails'
Plugin 'tpope/vim-eunuch'                   " unix shell
Plugin 'tpope/vim-tbone'                    " tmux commands
Plugin 'airblade/vim-gitgutter'             " file tree
Plugin 'scrooloose/nerdtree'                " source tree file
Plugin 'Lokaltog/powerline'
Plugin 'mileszs/ack.vim'                    " search in files
call vundle#end()            " required

syntax enable
filetype plugin indent on

let g:netrw_home="~/.vim/backup"

" Open vimrc with <leader>v
nmap <leader>v :edit $MYVIMRC<CR>
nmap <leader>sv :source $MYVIMRC<cr>

if &t_Co > 2 || has("gui_running")
  set hlsearch
  nmap <silent> <leader>h :silent :nohlsearch<CR>
endif

autocmd BufWritePre * :%s/\s\+$//e

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" COLORS
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
set t_Co=256
set background=dark
colorscheme solarized

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" FOLDING
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
set foldmethod=indent
set foldnestmax=10
set nofoldenable
set foldlevel=1
autocmd InsertEnter * if !exists('w:last_fdm') | let w:last_fdm=&foldmethod | setlocal foldmethod=manual | endif
autocmd InsertLeave,WinLeave * if exists('w:last_fdm') | let &l:foldmethod=w:last_fdm | unlet w:last_fdm | endif
nnoremap <space> za

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" UNBIND KEYS
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
"nnoremap <Left> <nop>
"nnoremap <Right> <nop>
"nnoremap <Up> <nop>
"nnoremap <Down> <nop>

" Tab spacing/size
set tabstop=2 "number of spaces on tab
set shiftwidth=2 "number of spaces to ident
set softtabstop=2
set expandtab "convert tabs to spaces
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
set ignorecase "ignore case when searching
set smartcase
set incsearch
set showmatch
set matchtime=2
set ruler "show cursor pos on status bar
set number "show line number
set relativenumber
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

" %% as current dir
cnoremap %% <C-R>=expand("%:h")."/"<CR>

cnoremap cb 1,100bdelete
"
" %f as current file
cnoremap %f <C-R>=expand("%")<CR>

" Clear the search buffer when hitting return
function! MapCR()
  nnoremap <cr> :nohlsearch<cr>:redraw!<cr>
endfunction
call MapCR()
nnoremap <leader><leader> ^

set completeopt=menu,menuone,longest
set pumheight=10

set wildignore+=*/.hg/*,*/.svn/*
set wildignore+=*.o,moc_*.cpp,*.exe,*.qm
set wildignore+=.gitkeep,.DS_Store

" Toggle paste mode with <leader>p
set pastetoggle=<leader>p
function! PasteCB()
  set paste
  set nopaste
endfunction

" Switch buffers with <leader>ea
map <leader>ea :b#<CR>

" Save/quit typos
cab W w| cab Q q| cab Wq wq| cab wQ wq| cab WQ wq| cab Bd bd| cab Wa wa| cab WA wa

autocmd CursorHold * checktime

inoremap jj <esc>

" Keep line index when reopening a file
autocmd BufReadPost *
  \ if line("'\"") > 0 && line("'\"") <= line("$") |
  \   exe "normal g`\"" |
  \ endif

" Sudo to write
cnoremap w!! w !sudo tee % >/dev/null

" Toggle invisible characters
map <leader>l :set list!<CR>

imap <c-l> <space>=><space>
map <leader>e :edit %%


" set winwidth=84
" set winheight=10
" set winminheight=10
" set winheight=999

" Surround word with separators
nnoremap <leader>" viw<esc>a"<esc>hbi"<esc>lel
nnoremap <leader>' viw<esc>a'<esc>hbi'<esc>lel
nnoremap <leader>( viw<esc>a(<esc>hbi)<esc>lel
nnoremap <leader>[ viw<esc>a[<esc>hbi]<esc>lel

"""""""""""""""""""""""
" WINDOW MANAGEMENT   "
"""""""""""""""""""""""

" Split
noremap <C-\> :100vsp<CR>
noremap <C--> :sp<CR>

" Resize
noremap <Up> <C-w>+
noremap <Down> <C-w>-
noremap <Left> <C-w>>
noremap <Right> <C-w><

" Move around
noremap <C-j> <C-w>j
noremap <C-k> <C-w>k
noremap <C-h> <C-w>h
noremap <C-l> <C-w>l

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" FUNCTIONS
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

function! OpenTestAlternate()
  let new_file = AlternateForCurrentFile()
  exec ':vsp ' . new_file
endfunction
function! AlternateForCurrentFile()
  let current_file = expand("%")
  let new_file = current_file
  let in_spec = match(current_file, '^spec/') != -1
  let going_to_spec = !in_spec
  let in_app = match(current_file, '\<buinsess\>') || match(current_file, '\<controllers\>') != -1 || match(current_file, '\<models\>') != -1 || match(current_file, '\<views\>') != -1 || match(current_file, '\<helpers\>') != -1
  if going_to_spec
    if in_app
      let new_file = substitute(new_file, '^app/', '', '')
    end
    let new_file = substitute(new_file, '\.rb$', '_spec.rb', '')
    let new_file = 'spec/' . new_file
  else
    let new_file = substitute(new_file, '_spec\.rb$', '.rb', '')
    let new_file = substitute(new_file, '^spec/', '', '')
    if in_app
      let new_file = 'app/' . new_file
    end
  endif
  return new_file
endfunction

nnoremap <leader>. :call OpenTestAlternate()<cr>
nnoremap <leader>s <c-w>o :call OpenTestAlternate()<cr>

function! CleverTab()
  if strpart( getline('.'), 0, col('.')-1 ) =~ '^\s*$'
    return "\<Tab>"
  else
    return "\<C-N>"
  endif
endfunction
" inoremap <Tab> <C-R>=CleverTab()<CR>

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" PLUGINS
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

""""""""""""
" CtrlP    "
""""""""""""
nmap <C-B> :CtrlPBuffer<cr>
" Open buffer with <C-B>
let g:ctrlp_custom_ignore='\.git$\|\.pdf$'
let g:ctrlp_use_caching=0
let g:ctrlp_max_height=10
let g:ctrlp_extensions=['quickfix']
let g:ctrlp_user_command={
  \ 'types' : {
    \ 1: ['.git', 'cd %s && git ls-tree -r HEAD | grep -v -e "^\d\+\scommit" | cut -f 2']
    \ },
  \ 'fallback': 'find %s -name "tmp" -prune -o -print'
  \ }
nnoremap <C-f> :CtrlPFallback<CR>


""""""""""""
" Gist     "
""""""""""""
let g:gist_open_browser_after_post = 1
let g:gist_post_private = 1
let g:gist_detect_filetype = 1
let g:gist_clip_command = 'xclip -selection clipboard'
let g:github_token = $GITHUB_TOKEN

""""""""""""
" CTags    "
""""""""""""
set tags+=gems.tags

"""""""""""""
" Powerline "
"""""""""""""
set rtp+=~/.vim/bundle/powerline/powerline/bindings/vim
set noshowmode
set laststatus=2

"""""""""""""
"   Ack     "
"""""""""""""
if executable('ag')
  let g:ackprg = 'ag --vimgrep'
endif
nnoremap <Leader>a :exe 'Ack!' expand('<cword>')<cr>
cnoreabbrev Ack Ack!
cnoreabbrev G Ack!


"""""""""""""
" NERDTree  "
"""""""""""""
autocmd FileType nerdtree cnoreabbrev <buffer> bd <nop>

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" KeyBinds
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
nnoremap <leader>c :bufdo :bd<CR>
nnoremap <Tab> <c-w><c-w><c-w>=
nnoremap <C-n> :NERDTreeToggle<CR>
inoremap <C-@> <C-N>
