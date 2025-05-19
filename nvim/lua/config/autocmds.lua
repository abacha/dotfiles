local group = vim.api.nvim_create_augroup
local autocmd = vim.api.nvim_create_autocmd

group("UserAutocmds", { clear = true })

autocmd("BufWritePre", {
  group = "UserAutocmds",
  pattern = "*",
  command = [[%s/\s\+$//e]]
})

autocmd({ "BufNewFile", "BufRead" }, {
  group = "UserAutocmds",
  pattern = "*.slim",
  command = "setlocal filetype=slim"
})

autocmd("FileType", {
  group = "UserAutocmds",
  pattern = "asciidoc",
  command = "setlocal syntax=off"
})

autocmd("CursorHold", {
  group = "UserAutocmds",
  pattern = "*",
  command = "checktime"
})

autocmd("BufReadPost", {
  pattern = "*",
  callback = function()
    local line = vim.fn.line([['"]])
    if line > 0 and line <= vim.fn.line("$") then
      vim.cmd("normal! g`\"")
    end
  end,
})
