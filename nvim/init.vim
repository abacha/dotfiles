set runtimepath^=~/.vim runtimepath+=~/.vim/after
set runtimepath^=~/.config/nvim runtimepath+=~/.config/nvim/after
let &packpath = &runtimepath
source ~/.vimrc

"lua require('config.plugins')
"lua require('config.options')

lua require('config.plugins.copilot')
lua require('config.plugins.treesitter')
lua require('config.plugins.nvim-cmp')
lua require('config.plugins.telescope')
