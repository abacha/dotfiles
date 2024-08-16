set runtimepath^=~/.vim runtimepath+=~/.vim/after
let &packpath = &runtimepath
source ~/.vimrc
lua << EOF
require("copilot").setup {}
require("CopilotChat").setup {}
require('telescope').setup{
  defaults = {
    file_ignore_patterns = {"node_modules", ".git", "dist", "tmp", "vendor", ".rubocop_todo", "log", "documentation", "coverage"}
  }
}
EOF
set runtimepath^=~/.config/nvim runtimepath+=~/.config/nvim/after
