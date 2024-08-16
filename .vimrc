set nocompatible "use vim defaults
filetype off
let mapleader=","
let g:netrw_home="~/.vim/backup"
set encoding=utf-8
set fileencoding=utf-8


""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" PLUGINS
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
call plug#begin('~/.vim/plugged')
Plug 'altercation/vim-colors-solarized'
Plug 'mattn/gist-vim'                     " create gists
Plug 'mattn/webapi-vim'                   " dependency: gist-vim
Plug 'tpope/vim-endwise'                  " auto close blocks
Plug 'tpope/vim-fugitive'                 " git helpers
Plug 'tpope/vim-eunuch'                   " unix shell
Plug 'roxma/vim-tmux-clipboard'           " tmux clipboard
Plug 'airblade/vim-gitgutter'             " git diff in sign col
Plug 'scrooloose/nerdtree'                " source tree file
Plug 'nvim-telescope/telescope.nvim'      " search in files
Plug 'kdheepak/lazygit.nvim'              " lazygit
Plug 'sheerun/vim-polyglot'               " Syntax highlight

" Copilot
Plug 'nvim-lua/plenary.nvim'
Plug 'zbirenbaum/copilot.lua'
Plug 'CopilotC-Nvim/CopilotChat.nvim'
call plug#end()


""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Commands
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
filetype plugin indent on
" Open vimrc with <leader>v
nmap <leader>v :edit ~/.vimrc<CR>
nmap <leader>sv :source $MYVIMRC<cr>

if &t_Co > 2 || has("gui_running")
  set hlsearch
  nmap <silent> <leader>h :silent :nohlsearch<CR>
endif

autocmd BufWritePre * :%s/\s\+$//e
autocmd BufNewFile,BufRead *.slim setlocal filetype=slim

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" COLORS
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
syntax enable
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

" Tab spacing/size
set tabstop=2          " number of spaces on tab
set softtabstop=2      " number of spaces on tab
set shiftwidth=2       " number of spaces to indent
set expandtab          " convert tabs to spaces
set smarttab           " insert tabs on the start of a line according to shiftwidth

set backspace=indent,eol,start
set listchars=tab:▸\ ,eol:¬,trail:·,precedes:«,extends:»
set textwidth=120
set linebreak
set showbreak=…

" Screen offset
set sidescroll=8
set scrolloff=8

set formatprg=par\ -TbgqRw80
set autoindent
set smartindent
set ignorecase        " ignore case when searching
set smartcase         " ignore case if search pattern is lowercase
set incsearch         " show search matches as you type
set showmatch         " highlight matching [{()}]
set matchtime=2
set ruler             " show cursor pos on status bar
set number            " show line number
set relativenumber    " show relative line number
set autoread          " auto reload file if changed outside vim
set wildmenu          " show list of matches when tab completing
set wildmode=list:longest
set shortmess=atI     " shorten messages
set timeoutlen=500
set wrap
set wrapmargin=120
set visualbell       " no crazy beeping
set hidden
set title
set cc=+1

command! -nargs=* Wrap set wrap linebreak nolist
set backupdir=~/.vim/backup,~/tmp,/var/tmp,/tmp
set directory=~/.vim/backup,~/tmp,/var/tmp,/tmp

" %% as current dir
cnoremap %% <C-R>=expand("%:h")."/"<CR>
" <l>cb as buffer delete
cnoremap cb 1,100bdelete
" %f as current file
cnoremap %f <C-R>=expand("%")<CR>

" Clear the search buffer when hitting return
function! MapCR()
  nnoremap <cr> :nohlsearch<cr>:redraw!<cr>
endfunction
call MapCR()
nnoremap <leader><leader> ^
nnoremap \\ $

set completeopt=menu,menuone,longest
set pumheight=10

set wildignore+=*/.hg/*,*/.svn/*
set wildignore+=*.o,moc_*.cpp,*.exe,*.qm
set wildignore+=.gitkeep,.DS_Store

" Toggle paste mode with <l>p
set pastetoggle=<leader>p
function! PasteCB()
  set paste
  set nopaste
endfunction

" Switch buffers with <leader>ea
map <leader>ea :b#<CR>

" Save/quit typos
cab W w| cab Q q| cab Wq wq| cab wQ wq| cab WQ wq| cab Bd bd| cab Wa wa| cab WA wa| cab X x

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

"""""""""""""""""""""""
" WINDOW MANAGEMENT   "
"""""""""""""""""""""""

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

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" PLUGINS
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

""""""""""""
" Gist     "
""""""""""""
let g:gist_open_browser_after_post = 1
let g:gist_post_private = 1
let g:gist_detect_filetype = 1
let g:gist_clip_command = 'xclip -selection clipboard'
let g:github_token = $GITHUB_TOKEN

"""""""""""""
" Telescope "
"""""""""""""
nnoremap <leader>ff <cmd>Telescope find_files<cr>
nnoremap <leader>fg <cmd>Telescope live_grep<cr>
nnoremap <leader>fb <cmd>Telescope buffers<cr>
nnoremap <leader>fh <cmd>Telescope help_tags<cr>


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
nnoremap <F3> :tabprevious<CR>
nnoremap <F4> :tabNext<CR>
vnoremap <C-y> :%y+<CR>
