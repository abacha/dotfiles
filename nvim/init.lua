require("config.preconfig")                     -- Pre-configuration settings
require("config.plugins")

-- Plugins settings
require("config.plugins.configs")               -- Plugin configurations
require("config.plugins.copilot")               -- GitHub Copilot configuration
require("config.plugins.treesitter")            -- Treesitter configuration
require("config.plugins.nvim-cmp")              -- Autocompletion configuration
require("config.plugins.telescope")             -- Telescope fuzzy finder config
require("config.plugins.lsp")                   -- LSP configuration
require("config.plugins.code_companion")        -- Code Companion configuration

-- Core Neovim settings
require("config.options")
require("config.mappings")
require("config.autocmds")
require("config.folds")

-- Functions and utilities
require("config.functions.rails_test_alternate")
require("config.functions.reload_config")         -- Reload Neovim configuration
