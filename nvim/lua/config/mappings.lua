local map = vim.keymap.set

-- Window management
map("n", "<C-j>", "<C-w>j")
map("n", "<C-k>", "<C-w>k")
map("n", "<C-h>", "<C-w>h")
map("n", "<C-l>", "<C-w>l")
map("n", "<Up>", "<C-w>+")
map("n", "<Down>", "<C-w>-")
map("n", "<Left>", "<C-w>>")
map("n", "<Right>", "<C-w><")

map("n", "<leader>v", ":edit $MYVIMRC<CR>")         -- Edit init.vim/init.lua
map("n", "<leader>sv", ":source $MYVIMRC<CR>")      -- Source init.vim/init.lua
map("n", "<leader>c", ":bufdo :bd<CR>")             -- Close all buffers
map("n", "<Tab>", "<C-w>w")                         -- Switch window
map("n", "<C-n>", ":NERDTreeToggle<CR>")            -- Toggle NERDTree
map("n", "<F3>", ":tabprevious<CR>")                -- Go to previous tab
map("n", "<F4>", ":tabnext<CR>")                    -- Go to next tab
map("v", "<C-y>", '"+y')                            -- Yank to system clipboard in visual mode
map("n", "<leader>gc", ":CopilotChat<CR>")          -- Open Copilot Chat
map("c", "%%", [[<C-R>=expand("%:h")."/"<CR>]])     -- Insert current file's directory in command mode
map("c", "%f", [[<C-R>=expand("%")<CR>]])           -- Insert current file's name in command mode
map("n", "<leader><leader>", "^")                   -- Jump to first non-blank character
map("n", "\\\\", "$")                               -- Jump to end of line
map("n", "<leader>ea", ":b#<CR>")                   -- Switch to alternate buffer
map("n", "<space>", "za")                           -- Toggle fold
map("n", "<leader>l", ":set list!<CR>")             -- Toggle listchars
map("n", "<leader>e", ":edit expand(\"%%\")")       -- Edit file in current directory
map("i", "jj", "<Esc>")                             -- Exit insert mode with 'jj'

-- Paste toggle
vim.api.nvim_create_user_command("TogglePaste", function()
  local paste = vim.opt.paste:get()
  vim.opt.paste = not paste
  print("Paste Mode " .. (not paste and "Enabled" or "Disabled"))
end, {})

map("n", "<leader>p", ":TogglePaste<CR>")
