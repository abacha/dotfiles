local lspconfig = require('lspconfig')
local capabilities = require('cmp_nvim_lsp').default_capabilities()

lspconfig.tsserver.setup({
 capabilities = capabilities,
})

lspconfig.solargraph.setup({
 capabilities = capabilities,
})
