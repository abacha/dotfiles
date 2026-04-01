local ok, treesitter = pcall(require, "nvim-treesitter")

if not ok then
  return
end

treesitter.setup({
  install_dir = vim.fn.stdpath("data") .. "/site",
})

vim.api.nvim_create_autocmd("FileType", {
  callback = function(args)
    pcall(vim.treesitter.start, args.buf)
  end,
})
