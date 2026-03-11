local capabilities = require('cmp_nvim_lsp').default_capabilities()

vim.lsp.config('ts_ls', {
  capabilities = capabilities,
})
vim.lsp.enable('ts_ls')

vim.lsp.config('solargraph', {
  capabilities = capabilities,
})
vim.lsp.enable('solargraph')
