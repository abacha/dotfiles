require("config.preconfig")

-- Add legacy Vim config
vim.cmd('set runtimepath^=~/.vim')
vim.cmd('set runtimepath^=~/.config/nvim')
vim.o.packpath = vim.o.runtimepath
vim.cmd('source ~/.vimrc')

require('config.plugins.configs')       -- Plugin configurations
require('config.plugins.copilot')       -- GitHub Copilot configuration
require('config.plugins.treesitter')    -- Treesitter configuration
require('config.plugins.nvim-cmp')      -- Autocompletion configuration
require('config.plugins.telescope')     -- Telescope fuzzy finder config
