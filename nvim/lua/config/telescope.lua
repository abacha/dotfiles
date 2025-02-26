local telescope = require("telescope")
local lga_actions = require("telescope-live-grep-args.actions")
local actions = require('telescope.actions')

telescope.setup {
  defaults = {
    --file_ignore_patterns = {"node_modules/", ".git/", "dist/", "tmp/", "vendor/", ".rubocop_todo", "*.log", "coverage/"},
    path_display = {"truncate"},
    hidden = true,
    mappings = {
      i = {
        ["<C-q>"] = actions.smart_send_to_qflist + actions.open_qflist,
      },
      n = {
        ["<C-e>"] = actions.delete_buffer,
        ["<C-q>"] = actions.smart_send_to_qflist + actions.open_qflist,
        ["<C-Down>"] = actions.cycle_history_next,
        ["<C-Up>"] = actions.cycle_history_prev,
      },
    },
  },
  extensions = {
    live_grep_args = {
      auto_quoting = true,
      mappings = {
        i = {
          --["<C-k>"] = lga_actions.quote_prompt(),
          --["<C-i>"] = lga_actions.quote_prompt({ postfix = " --iglob " }),
          --["<C-space>"] = actions.to_fuzzy_refine,
        },
      },
    }
  }
}
telescope.load_extension("live_grep_args")
