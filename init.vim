set runtimepath^=~/.vim runtimepath+=~/.vim/after
let &packpath = &runtimepath
source ~/.vimrc
lua << EOF
require("CopilotChat").setup { debug = false }
EOF
set runtimepath^=~/.config/nvim runtimepath+=~/.config/nvim/after
