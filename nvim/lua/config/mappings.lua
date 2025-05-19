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

-- Atalhos úteis
map("n", "<leader>v", ":edit $MYVIMRC<CR>")
map("n", "<leader>sv", ":source $MYVIMRC<CR>")
map("n", "<leader>c", ":bufdo :bd<CR>")
map("n", "<Tab>", "<C-w>w")
map("n", "<C-n>", ":NERDTreeToggle<CR>")
map("n", "<F3>", ":tabprevious<CR>")
map("n", "<F4>", ":tabnext<CR>")
map("v", "<C-y>", '"+y')
map("n", "<leader>gc", ":CopilotChat<CR>")
map("c", "%%", [[<C-R>=expand("%:h")."/"<CR>]])
map("c", "%f", [[<C-R>=expand("%")<CR>]])
map("n", "<leader><leader>", "^")
map("n", "\\\\", "$")
map("n", "<leader>ea", ":b#<CR>")
map("n", "<space>", "za")
map("n", "<leader>l", ":set list!<CR>")
map("n", "<leader>e", ":edit %%")
map("i", "jj", "<Esc>")
map("i", "<C-i>", 'copilot#Accept("<CR>")', { expr = true, silent = true, script = true })

-- Paste toggle
vim.api.nvim_create_user_command("TogglePaste", function()
  local paste = vim.opt.paste:get()
  vim.opt.paste = not paste
  print("Paste Mode " .. (not paste and "Enabled" or "Disabled"))
end, {})

map("n", "<leader>p", ":TogglePaste<CR>")
