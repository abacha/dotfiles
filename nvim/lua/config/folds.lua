vim.opt.foldmethod = "indent"
vim.opt.foldnestmax = 10
vim.opt.foldenable = false
vim.opt.foldlevel = 1

vim.api.nvim_create_autocmd("InsertEnter", {
  callback = function()
    if not vim.w.last_fdm then
      vim.w.last_fdm = vim.wo.foldmethod
      vim.wo.foldmethod = "manual"
    end
  end,
})

vim.api.nvim_create_autocmd({ "InsertLeave", "WinLeave" }, {
  callback = function()
    if vim.w.last_fdm then
      vim.wo.foldmethod = vim.w.last_fdm
      vim.w.last_fdm = nil
    end
  end,
})
