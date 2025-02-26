-- Plugin management using packer.nvim
require('packer').startup(function()
  use 'wbthomason/packer.nvim'
  use 'nvim-lua/plenary.nvim'
  use 'altercation/vim-colors-solarized'
  use 'mattn/gist-vim'
  use 'mattn/webapi-vim'
  use 'tpope/vim-endwise'
  use 'tpope/vim-fugitive'
  use 'tpope/vim-eunuch'
  use 'roxma/vim-tmux-clipboard'
  use 'airblade/vim-gitgutter'
  use 'scrooloose/nerdtree'
  use 'nvim-telescope/telescope.nvim'
  use 'nvim-telescope/telescope-live-grep-args.nvim'
  use 'kdheepak/lazygit.nvim'
  use {'nvim-treesitter/nvim-treesitter', run = ':TSUpdate'}
  use 'zbirenbaum/copilot.lua'
  use 'CopilotC-Nvim/CopilotChat.nvim'
  use {'neoclide/coc.nvim', branch = 'release'}
  use 'neoclide/coc-eslint'
  use 'neoclide/coc-solargraph'
end)
