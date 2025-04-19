set runtimepath^=~/.vim runtimepath+=~/.vim/after
set runtimepath^=~/.config/nvim runtimepath+=~/.config/nvim/after
let &packpath = &runtimepath
source ~/.vimrc

"lua require('config.plugins')
"lua require('config.options')

lua require('config.copilot')
lua require('config.treesitter')
"lua require('config.coc')
lua require('config.nvim-cmp')
lua require('config.telescope')
