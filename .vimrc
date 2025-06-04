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

Plug 'zbirenbaum/copilot-cmp'

call plug#end()
