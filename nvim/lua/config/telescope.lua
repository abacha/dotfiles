local telescope = require("telescope")
--local lga_actions = require("telescope-live-grep-args.actions")

telescope.setup {
  defaults = {
    file_ignore_patterns = {"node_modules", ".git", "dist", "tmp", "vendor", ".rubocop_todo", "log", "documentation", "coverage"},
    path_display = {"truncate"}
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
