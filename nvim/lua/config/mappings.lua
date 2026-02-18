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
map("n", "<leader>sv", ":lua ReloadConfig()<CR>")      -- Source init.vim/init.lua
map("n", "<leader>bc", ":bufdo :bd<CR>")             -- Close all buffers
map("n", "<Tab>", "<C-w>w")                         -- Switch window
map("n", "<C-n>", ":NvimTreeToggle<CR>")            -- Toggle nvim-tree
map("n", "<leader>nf", ":NvimTreeFindFile<CR>")      -- Find file in nvim-tree
map("n", "<leader>nr", ":NvimTreeRefresh<CR>")       -- Refresh nvim-tree
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

map("n", "<leader>.", ":lua OpenTestAlternate()<CR>", { silent = true })

-- Clear search highlights
map("n", "<CR>", function()
  if vim.fn.getwinvar(vim.fn.win_getid(), "&buftype") == "quickfix" then
    return "<CR>"
  else
    return ":silent! nohlsearch<CR>:silent! redraw!<CR>"
  end
end, { expr = true })

-- Paste toggle
vim.api.nvim_create_user_command("TogglePaste", function()
  local paste = vim.opt.paste:get()
  vim.opt.paste = not paste
  print("Paste Mode " .. (not paste and "Enabled" or "Disabled"))
end, {})

map("n", "<leader>p", ":TogglePaste<CR>")

-- Custom command to delete current file and close the buffer safely
vim.api.nvim_create_user_command("DeleteFile", function()
  local buf = vim.api.nvim_get_current_buf()
  local file = vim.api.nvim_buf_get_name(buf)

  if file == "" then
    vim.notify("No file associated with current buffer", vim.log.levels.WARN)
    return
  end

  if vim.fn.confirm("Delete file?\n" .. file, "&Yes\n&No", 2) ~= 1 then
    return
  end

  local ok, err = os.remove(file)
  if not ok then
    vim.notify("Failed to delete file: " .. tostring(err), vim.log.levels.ERROR)
    return
  end

  vim.cmd("bdelete")
  vim.notify("Deleted: " .. file, vim.log.levels.INFO)
end, {})
