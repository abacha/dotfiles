local cmp = require('cmp')
local luasnip = require('luasnip')

require('luasnip.loaders.from_vscode').lazy_load()

cmp.setup({
 snippet = {
   expand = function(args)
     luasnip.lsp_expand(args.body)
   end,
 },
 mapping = {
   ['<C-b>'] = cmp.mapping.scroll_docs(-4),
   ['<C-f>'] = cmp.mapping.scroll_docs(4),
   ['<C-Space>'] = cmp.mapping.complete(),
   ['<C-e>'] = cmp.mapping.abort(),
   ['<CR>'] = cmp.mapping.confirm({ select = false }),
   ['<Down>'] = cmp.mapping.select_next_item(),
   ['<Up>'] = cmp.mapping.select_prev_item(),
   ['<Tab>'] = cmp.mapping(function(fallback)
     if cmp.visible() then
       cmp.select_next_item()
     elseif luasnip.expand_or_jumpable() then
       luasnip.expand_or_jump()
     else
       fallback()
     end
   end, { 'i', 's' }),
   ['<S-Tab>'] = cmp.mapping(function(fallback)
     if cmp.visible() then
       cmp.select_prev_item()
     elseif luasnip.jumpable(-1) then
       luasnip.jump(-1)
     else
       fallback()
     end
   end, { 'i', 's' }),
 },
 sources = {
   { name = "copilot" },
   { name = 'nvim_lsp' },
   { name = 'luasnip' },
   { name = 'buffer' },
   { name = 'path' },
 },
 sorting = {
   priority_weight = 2,
   comparators = {
     require("copilot_cmp.comparators").prioritize,

     -- Below is the default comparitor list and order for nvim-cmp
     cmp.config.compare.offset,
     -- cmp.config.compare.scopes, --this is commented in nvim-cmp too
     cmp.config.compare.exact,
     cmp.config.compare.score,
     cmp.config.compare.recently_used,
     cmp.config.compare.locality,
     cmp.config.compare.kind,
     cmp.config.compare.sort_text,
     cmp.config.compare.length,
     cmp.config.compare.order,
   },
 },
})

-- Use buffer source for `/` and `?`
cmp.setup.cmdline({ '/', '?' }, {
 mapping = cmp.mapping.preset.cmdline(),
 sources = {
   { name = 'buffer' }
 }
})

-- Use cmdline & path source for ':'
cmp.setup.cmdline(':', {
 mapping = cmp.mapping.preset.cmdline(),
 sources = cmp.config.sources({
   { name = 'path' }
 }, {
   { name = 'cmdline' }
 })
})

-- Unlike other completion sources, copilot can use other lines above or below an empty line to provide a completion. This can cause problematic for individuals that select menu entries with <TAB>. This behavior is configurable via cmp's config and the following code will make it so that the menu still appears normally, but tab will fallback to indenting unless a non-whitespace character has actually been typed.
local has_words_before = function()
  if vim.api.nvim_buf_get_option(0, "buftype") == "prompt" then return false end
  local line, col = unpack(vim.api.nvim_win_get_cursor(0))
  return col ~= 0 and vim.api.nvim_buf_get_text(0, line-1, 0, line-1, col, {})[1]:match("^%s*$") == nil
end
cmp.setup({
  mapping = {
    ["<Tab>"] = vim.schedule_wrap(function(fallback)
      if cmp.visible() and has_words_before() then
        cmp.select_next_item({ behavior = cmp.SelectBehavior.Select })
      else
        fallback()
      end
    end),
  },
})
