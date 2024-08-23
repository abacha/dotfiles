set runtimepath^=~/.vim runtimepath+=~/.vim/after
let &packpath = &runtimepath
source ~/.vimrc
lua << EOF
require('copilot').setup({
  panel = {
    enabled = true,
    auto_refresh = false,
    keymap = {
      jump_prev = "[[",
      jump_next = "]]",
      accept = "<CR>",
      refresh = "gr",
      open = "<M-CR>"
    },
    layout = {
      position = "bottom", -- | top | left | right
      ratio = 0.4
    },
  },
  suggestion = {
    enabled = true,
    auto_trigger = true,
    hide_during_completion = true,
    debounce = 75,
    keymap = {
      accept = "<M-l>",
      accept_word = false,
      accept_line = false,
      next = "<M-]>",
      prev = "<M-[>",
      dismiss = "<C-]>",
    },
  },
})

require("CopilotChat").setup {}
require('telescope').setup{
  defaults = {
    file_ignore_patterns = {"node_modules", ".git", "dist", "tmp", "vendor", ".rubocop_todo", "log", "documentation", "coverage"},
    path_display = {"truncate"}
  }
}
require('telescope').load_extension("live_grep_args")
EOF
set runtimepath^=~/.config/nvim runtimepath+=~/.config/nvim/after
