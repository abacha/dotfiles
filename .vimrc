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
Plug 'nvim-lua/plenary.nvim'

Plug 'altercation/vim-colors-solarized'               " solarized theme
Plug 'mattn/gist-vim'                                 " create gists
Plug 'mattn/webapi-vim'                               " dependency: gist-vim
Plug 'tpope/vim-endwise'                              " auto close blocks
Plug 'tpope/vim-fugitive'                             " git helpers
Plug 'tpope/vim-eunuch'                               " unix shell
Plug 'roxma/vim-tmux-clipboard'                       " tmux clipboard
Plug 'airblade/vim-gitgutter'                         " git diff in sign col
Plug 'scrooloose/nerdtree'                            " source tree file
Plug 'nvim-telescope/telescope.nvim'                  " search in files
Plug 'nvim-telescope/telescope-live-grep-args.nvim'   " grep in files
Plug 'kdheepak/lazygit.nvim'                          " lazygit
Plug 'nvim-treesitter/nvim-treesitter', {'do': ':TSUpdate'}

" Copilot
Plug 'zbirenbaum/copilot.lua'
Plug 'CopilotC-Nvim/CopilotChat.nvim'


" nvim-cmp (Auto completion)
Plug 'hrsh7th/nvim-cmp'                               " Completion engine
Plug 'hrsh7th/cmp-nvim-lsp'                           " LSP source for nvim-cmp
Plug 'hrsh7th/cmp-buffer'                             " Buffer completions
Plug 'hrsh7th/cmp-path'                               " Path completions
Plug 'hrsh7th/cmp-cmdline'                            " Command-line completions
Plug 'L3MON4D3/LuaSnip'                               " Snippet engine
Plug 'saadparwaiz1/cmp_luasnip'                       " Snippet completions
Plug 'neovim/nvim-lspconfig'                          " LSP configurations

call plug#end()


""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Commands
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
filetype plugin indent on

if &t_Co > 2 || has("gui_running")
  set hlsearch
endif

autocmd BufWritePre * :%s/\s\+$//e
autocmd BufNewFile,BufRead *.slim setlocal filetype=slim
autocmd FileType asciidoc setlocal syntax=off

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


""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" CONFIGS
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Tab spacing/size
set tabstop=2                             " number of spaces on tab
set softtabstop=2                         " number of spaces on tab
set shiftwidth=2                          " number of spaces to indent
set expandtab                             " convert tabs to spaces
set smarttab                              " insert tabs on the start of a line according to shiftwidth

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
set ignorecase                            " ignore case when searching
set smartcase                             " ignore case if search pattern is lowercase
set incsearch                             " show search matches as you type
set showmatch                             " highlight matching [{()}]
set matchtime=2
set ruler                                 " show cursor pos on status bar
set number                                " show line number
set relativenumber                        " show relative line number
set autoread                              " auto reload file if changed outside vim
set wildmenu                              " show list of matches when tab completing
set wildmode=list:longest
set shortmess=atI                         " shorten messages
set timeoutlen=500
set wrap
set wrapmargin=120
set visualbell                            " no crazy beeping
set hidden
set title
set cc=+1
set statusline=%F%m%r%h%w\ [%l/%L]\ [%v]

command! -nargs=* Wrap set wrap linebreak nolist
set backupdir=~/.vim/backup,~/tmp,/var/tmp,/tmp
set directory=~/.vim/backup,~/tmp,/var/tmp,/tmp


set completeopt=menu,menuone,longest
set pumheight=10
set wildignore+=*/.hg/*,*/.svn/*,*.o,moc_*.cpp,*.exe,*.qm,.gitkeep,.DS_Store

" Toggle paste mode with <lead>p
function! TogglePaste()
    if(&paste == 0)
        set paste
        echo "Paste Mode Enabled"
    else
        set nopaste
        echo "Paste Mode Disabled"
    endif
endfunction
map <leader>p :call TogglePaste()<cr>


" Save/quit typos
cab W w| cab Q q| cab Wq wq| cab wQ wq| cab WQ wq| cab Bd bd| cab Wa wa| cab WA wa| cab X x

autocmd CursorHold * checktime

" Keep line index when reopening a file
autocmd BufReadPost *
  \ if line("'\"") > 0 && line("'\"") <= line("$") |
  \   exe "normal g`\"" |
  \ endif

" Sudo to write
cnoremap w!! w !sudo tee % >/dev/null


" set winwidth=84
" set winheight=10
" set winminheight=10
" set winheight=999

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" WINDOW MANAGEMENT   "
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

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
  let in_spec_lib = match(current_file, '^spec/lib/') != -1
  let going_to_spec = !in_spec

  if going_to_spec
    if match(current_file, '^app/') != -1
      let new_file = substitute(new_file, '^app/', '', '')
      let new_file = substitute(new_file, '\.rb$', '_spec.rb', '')
      let new_file = 'spec/' . new_file
    else
      let new_file = substitute(new_file, '^lib/', '', '')
      let new_file = substitute(new_file, '\.rb$', '_spec.rb', '')
      let new_file = 'spec/lib/' . new_file
    endif
  else
    let new_file = substitute(new_file, '_spec\.rb$', '.rb', '')
    if in_spec_lib
      let new_file = substitute(new_file, '^spec/lib/', 'lib/', '')
    else
      let new_file = substitute(new_file, '^spec/', 'app/', '')
    endif
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
nnoremap <leader>fr <cmd>Telescope resume<cr>
nnoremap <leader>ff <cmd>Telescope find_files<cr>
nnoremap <leader>fg :lua require("telescope").extensions.live_grep_args.live_grep_args()<cr>
nnoremap <leader>fb <cmd>Telescope buffers<cr>
nnoremap <leader>fh <cmd>Telescope help_tags<cr>
nnoremap <leader>fF :execute 'Telescope git_files default_text=' . expand('<cword>')<cr>
nnoremap <leader>fG :execute 'Telescope live_grep default_text=' . expand('<cword>')<cr>


"""""""""""""
" NERDTree  "
"""""""""""""
autocmd FileType nerdtree cnoreabbrev <buffer> bd <nop>


""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" KeyBinds
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Open vimrc with <lead>v
nnoremap <leader>v :edit ~/.vimrc<CR>

" Reload vimrc with <lead>sv
nnoremap <leader>sv :source $MYVIMRC<CR>

" Clear buffer with <lead>c
nnoremap <leader>c :bufdo :bd<CR>

" Navigate on panes with tab
nnoremap <Tab> <c-w>w

" Open NERDTree with <C-n>
nnoremap <C-n> :NERDTreeToggle<CR>

" Previous tab with <F3>
nnoremap <F3> :tabprevious<CR>

" Next tab with <F4>
nnoremap <F4> :tabnext<CR>

" Copy selection to clipboard with <C-y>
vnoremap <C-y> "+y

" Open Copilot with <lead>gc
nnoremap <leader>gc :CopilotChat<CR>

" %% as current dir
cnoremap %% <C-R>=expand("%:h")."/"<CR>

" <lead>cb as buffer delete
cnoremap cb 1,100bdelete

" %f as current file
cnoremap %f <C-R>=expand("%")<CR>

" Clear the search buffer when hitting return
nnoremap <expr> <cr> getwinvar(win_getid(), '&buftype') ==# 'quickfix' ? "\<cr>" : ":silent! nohlsearch\<cr>:silent! redraw!\<cr>"


" Move to start of line with <lead><lead>
nnoremap <leader><leader> ^

" Move to end of line with \\
nnoremap \\ $

" Switch buffers with <leader>ea
nnoremap <leader>ea :b#<CR>

" Toggle fold with <space>
nnoremap <space> za

" Toggle invisible characters
nnoremap <leader>l :set list!<CR>

" Use <lead>e to open a file in new tab
map <leader>e :edit %%

" Map jj to <esc>
inoremap jj <esc>

" Map <C-i> to accept copilot suggestion
imap <silent><script><expr> <C-i> copilot#Accept("\<CR>")
