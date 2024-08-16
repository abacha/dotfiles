set nocompatible "use vim defaults
filetype off
let mapleader=","
let g:netrw_home="~/.vim/backup"


""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" ENCODING
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
set encoding=utf-8
set fileencoding=utf-8


""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" PLUGINS
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
set rtp+=~/.vim/bundle/Vundle.vim
call vundle#begin()
Plugin 'VundleVim/Vundle.vim'

" Bundles
Plugin 'altercation/vim-colors-solarized'
Plugin 'abacha/ctrlp.vim'                   " fuzzy finder
Plugin 'junegunn/fzf'
Plugin 'mattn/gist-vim'                     " create gists
Plugin 'mattn/webapi-vim'                   " dependency: gist-vim
Plugin 'tpope/vim-endwise'                  " auto close blocks
Plugin 'tpope/vim-fugitive'                 " git helpers
Plugin 'tpope/vim-eunuch'                   " unix shell
Plugin 'roxma/vim-tmux-clipboard'           " tmux clipboard
Plugin 'airblade/vim-gitgutter'             " git diff in sign col
Plugin 'scrooloose/nerdtree'                " source tree file
Plugin 'nvim-telescope/telescope.nvim'      " search in files
Plugin 'kdheepak/lazygit.nvim'              " lazygit
Plugin 'sheerun/vim-polyglot'               " Syntax highlight

" Copilot
Plugin 'nvim-lua/plenary.nvim'
Plugin 'zbirenbaum/copilot.lua'
Plugin 'CopilotC-Nvim/CopilotChat.nvim'

"Plugin 'neoclide/coc.nvim', {'branch': 'release'}
call vundle#end()            " required

filetype plugin indent on


""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Commands
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

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
set tabstop=2         " number of spaces on tab
set shiftwidth=2      " number of spaces to indent
set softtabstop=2
set expandtab         " convert tabs to spaces
set smarttab

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
set ignorecase       " ignore case when searching
set smartcase
set incsearch
set showmatch
set matchtime=2
set ruler            " show cursor pos on status bar
set number           " show line number
set relativenumber
set autoread
set wildmenu
set wildmode=list:longest
set shortmess=atI
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




""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" CoC
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

"" https://raw.githubusercotent.com/neoclide/coc.nvim/master/doc/coc-example-config.vim
"
"" Some servers have issues with backup files, see #649
"set nobackup
"set nowritebackup
"
"" Having longer updatetime (default is 4000 ms = 4s) leads to noticeable
"" delays and poor user experience
"set updatetime=300
"
"" Always show the signcolumn, otherwise it would shift the text each time
"" diagnostics appear/become resolved
"set signcolumn=yes
"
"" Use tab for trigger completion with characters ahead and navigate
"" NOTE: There's always complete item selected by default, you may want to enable
"" no select by `"suggest.noselect": true` in your configuration file
"" NOTE: Use command ':verbose imap <tab>' to make sure tab is not mapped by
"" other plugin before putting this into your config
"inoremap <silent><expr> <TAB>
"      \ coc#pum#visible() ? coc#pum#next(1) :
"      \ CheckBackspace() ? "\<Tab>" :
"      \ coc#refresh()
"inoremap <expr><S-TAB> coc#pum#visible() ? coc#pum#prev(1) : "\<C-h>"
"
"" Make <CR> to accept selected completion item or notify coc.nvim to format
"" <C-g>u breaks current undo, please make your own choice
"inoremap <silent><expr> <CR> coc#pum#visible() ? coc#pum#confirm()
"                              \: "\<C-g>u\<CR>\<c-r>=coc#on_enter()\<CR>"
"
"function! CheckBackspace() abort
"  let col = col('.') - 1
"  return !col || getline('.')[col - 1]  =~# '\s'
"endfunction
"
"" Use <c-space> to trigger completion
"if has('nvim')
"  inoremap <silent><expr> <c-space> coc#refresh()
"else
"  inoremap <silent><expr> <c-@> coc#refresh()
"endif
"
"" Use `[g` and `]g` to navigate diagnostics
"" Use `:CocDiagnostics` to get all diagnostics of current buffer in location list
"nmap <silent> [g <Plug>(coc-diagnostic-prev)
"nmap <silent> ]g <Plug>(coc-diagnostic-next)
"
"" GoTo code navigation
"nmap <silent> gd <Plug>(coc-definition)
"nmap <silent> gy <Plug>(coc-type-definition)
"nmap <silent> gi <Plug>(coc-implementation)
"nmap <silent> gr <Plug>(coc-references)
"
"" Use K to show documentation in preview window
"nnoremap <silent> K :call ShowDocumentation()<CR>
"
"function! ShowDocumentation()
"  if CocAction('hasProvider', 'hover')
"    call CocActionAsync('doHover')
"  else
"    call feedkeys('K', 'in')
"  endif
"endfunction
"
"" Highlight the symbol and its references when holding the cursor
"autocmd CursorHold * silent call CocActionAsync('highlight')
"
"" Symbol renaming
"nmap <leader>rn <Plug>(coc-rename)
"
"" Formatting selected code
"xmap <leader>f  <Plug>(coc-format-selected)
"nmap <leader>f  <Plug>(coc-format-selected)
"
"augroup mygroup
"  autocmd!
"  " Setup formatexpr specified filetype(s)
"  autocmd FileType typescript,json setl formatexpr=CocAction('formatSelected')
"  " Update signature help on jump placeholder
"  autocmd User CocJumpPlaceholder call CocActionAsync('showSignatureHelp')
"augroup end
"
"" Applying code actions to the selected code block
"" Example: `<leader>aap` for current paragraph
""xmap <leader>a  <Plug>(coc-codeaction-selected)
""nmap <leader>a  <Plug>(coc-codeaction-selected)
"
"" Remap keys for applying code actions at the cursor position
"nmap <leader>ac  <Plug>(coc-codeaction-cursor)
"" Remap keys for apply code actions affect whole buffer
"nmap <leader>as  <Plug>(coc-codeaction-source)
"" Apply the most preferred quickfix action to fix diagnostic on the current line
"nmap <leader>qf  <Plug>(coc-fix-current)
"
"" Remap keys for applying refactor code actions
"nmap <silent> <leader>re <Plug>(coc-codeaction-refactor)
"xmap <silent> <leader>r  <Plug>(coc-codeaction-refactor-selected)
"nmap <silent> <leader>r  <Plug>(coc-codeaction-refactor-selected)
"
"" Run the Code Lens action on the current line
"nmap <leader>cl  <Plug>(coc-codelens-action)
"
"" Map function and class text objects
"" NOTE: Requires 'textDocument.documentSymbol' support from the language server
"xmap if <Plug>(coc-funcobj-i)
"omap if <Plug>(coc-funcobj-i)
"xmap af <Plug>(coc-funcobj-a)
"omap af <Plug>(coc-funcobj-a)
"xmap ic <Plug>(coc-classobj-i)
"omap ic <Plug>(coc-classobj-i)
"xmap ac <Plug>(coc-classobj-a)
"omap ac <Plug>(coc-classobj-a)
"
"" Remap <C-X> and <C-x> to scroll float windows/popups
"if has('nvim-0.4.0') || has('patch-8.2.0750')
"  nnoremap <silent><nowait><expr> <C-X> coc#float#has_scroll() ? coc#float#scroll(1) : "\<C-X>"
"  nnoremap <silent><nowait><expr> <C-x> coc#float#has_scroll() ? coc#float#scroll(0) : "\<C-x>"
"  inoremap <silent><nowait><expr> <C-X> coc#float#has_scroll() ? "\<c-r>=coc#float#scroll(1)\<cr>" : "\<Right>"
"  inoremap <silent><nowait><expr> <C-x> coc#float#has_scroll() ? "\<c-r>=coc#float#scroll(0)\<cr>" : "\<Left>"
"  vnoremap <silent><nowait><expr> <C-X> coc#float#has_scroll() ? coc#float#scroll(1) : "\<C-X>"
"  vnoremap <silent><nowait><expr> <C-x> coc#float#has_scroll() ? coc#float#scroll(0) : "\<C-x>"
"endif
"
"" Use CTRL-S for selections ranges
"" Requires 'textDocument/selectionRange' support of language server
"nmap <silent> <C-s> <Plug>(coc-range-select)
"xmap <silent> <C-s> <Plug>(coc-range-select)
"
"" Add `:Format` command to format current buffer
"command! -nargs=0 Format :call CocActionAsync('format')
"
"" Add `:Fold` command to fold current buffer
"command! -nargs=? Fold :call     CocAction('fold', <f-args>)
"
"" Add `:OR` command for organize imports of the current buffer
"command! -nargs=0 OR   :call     CocActionAsync('runCommand', 'editor.action.organizeImport')
"
"" Add (Neo)Vim's native statusline support
"" NOTE: Please see `:h coc-status` for integrations with external plugins that
"" provide custom statusline: lightline.vim, vim-airline
"set statusline^=%{coc#status()}%{get(b:,'coc_current_function','')}
"
"" Mappings for CoCList
"" Show all diagnostics
"nnoremap <silent><nowait> <space>a  :<C-u>CocList diagnostics<cr>
"" Manage extensions
"nnoremap <silent><nowait> <space>e  :<C-u>CocList extensions<cr>
"" Show commands
"nnoremap <silent><nowait> <space>c  :<C-u>CocList commands<cr>
"" Find symbol of current document
"nnoremap <silent><nowait> <space>o  :<C-u>CocList outline<cr>
"" Search workspace symbols
"nnoremap <silent><nowait> <space>s  :<C-u>CocList -I symbols<cr>
"" Do default action for next item
"nnoremap <silent><nowait> <space>j  :<C-u>CocNext<CR>
"" Do default action for previous item
"nnoremap <silent><nowait> <space>k  :<C-u>CocPrev<CR>
"" Resume latest coc list
"nnoremap <silent><nowait> <space>p  :<C-u>CocListResume<CR>n
