set runtimepath^=~/.vim runtimepath+=~/.vim/after
set runtimepath^=~/.config/nvim runtimepath+=~/.config/nvim/after
let &packpath = &runtimepath
source ~/.vimrc

lua require('config.copilot')
"lua require('config.telescope')
