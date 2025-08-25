return require('packer').startup(function(use)
  use 'wbthomason/packer.nvim'

  -- Themes and UI
  use 'Tsuzat/NeoSolarized.nvim'
  use 'airblade/vim-gitgutter'
  use {
    'nvim-tree/nvim-tree.lua',
    config = function()
      require('nvim-tree').setup{
        renderer = {
          icons = {
            show = {
              file = false,
              folder = false,
              folder_arrow = true,
              git = true,
            },
            glyphs = {
              folder = {
                arrow_closed = "📁",
                arrow_open = "📂",
              },
              git = {
                unstaged = "✏️",
                staged = "✅",
                unmerged = "🔴",
                renamed = "➡️",
                untracked = "❓",
                deleted = "❌",
                ignored = "🙈",
              },
            },
          },
        },
      }
    end
  }

  -- Utilities
  use 'mattn/gist-vim'
  use 'mattn/webapi-vim'
  use 'tpope/vim-endwise'
  use 'tpope/vim-fugitive'
  use 'tpope/vim-eunuch'
  use 'roxma/vim-tmux-clipboard'

  -- Telescope and dependencies
  use 'nvim-lua/plenary.nvim'
  use 'nvim-telescope/telescope.nvim'
  use 'nvim-telescope/telescope-live-grep-args.nvim'
  use 'kdheepak/lazygit.nvim'

  -- Treesitter
  use { 'nvim-treesitter/nvim-treesitter', run = ':TSUpdate' }

  -- Testing
  use 'vim-test/vim-test'
  use 'tpope/vim-dispatch'

  -- Copilot and AI
  use 'zbirenbaum/copilot.lua'
  use 'CopilotC-Nvim/CopilotChat.nvim'

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
