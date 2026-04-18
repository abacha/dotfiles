return require('packer').startup(function(use)
  use 'wbthomason/packer.nvim'

  -- Themes and UI
  use 'Tsuzat/NeoSolarized.nvim'
  use 'nvim-lualine/lualine.nvim'
  use 'lewis6991/gitsigns.nvim'

  -- Utilities
  use 'mattn/gist-vim'
  use 'mattn/webapi-vim'
  use 'tpope/vim-endwise'
  use 'tpope/vim-fugitive'
  use 'tpope/vim-eunuch'
  use 'christoomey/vim-tmux-navigator'
  use 'roxma/vim-tmux-clipboard'
  use 'nvim-tree/nvim-tree.lua'

  -- Telescope and dependencies
  use 'nvim-lua/plenary.nvim'
  use 'nvim-telescope/telescope.nvim'
  use 'nvim-telescope/telescope-live-grep-args.nvim'
  use 'kdheepak/lazygit.nvim'

  -- Treesitter
  use { 'nvim-treesitter/nvim-treesitter', run = ':TSUpdate' }

  -- Markdown preview
  use {
    'iamcco/markdown-preview.nvim',
    run = 'cd app && npm install',
    ft = { 'markdown' },
  }

  -- Testing
  use 'vim-test/vim-test'
  use 'tpope/vim-dispatch'

  -- GitHub
  use {
    'pwntester/octo.nvim',
    requires = {
      'nvim-lua/plenary.nvim',
      'nvim-telescope/telescope.nvim',
      'nvim-tree/nvim-web-devicons',
    }
  }

  -- Copilot and AI
  use 'zbirenbaum/copilot.lua'
  use 'CopilotC-Nvim/CopilotChat.nvim'

  -- Obsidian
  use {
    "epwalsh/obsidian.nvim",
    config = function()
      require("obsidian").setup({
        workspaces = {
          {
            name = "vault",
            path = "~/vault",
          },
        },
      })
    end,
  }

  -- Completion
  use 'hrsh7th/nvim-cmp'
  use 'hrsh7th/cmp-nvim-lsp'
  use 'hrsh7th/cmp-buffer'
  use 'hrsh7th/cmp-path'
  use 'hrsh7th/cmp-cmdline'
  use 'L3MON4D3/LuaSnip'
  use 'saadparwaiz1/cmp_luasnip'
  use 'neovim/nvim-lspconfig'
  use 'zbirenbaum/copilot-cmp'
end)
