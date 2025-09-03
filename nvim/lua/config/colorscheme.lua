-- Colors
vim.opt.termguicolors = true
vim.opt.background = "dark"

require("NeoSolarized").setup({
  style = "dark",
  transparent = true,
  terminal_colors = true,
  enable_italics = true,
  styles = {
    comments = { italic = true },
    keywords = { italic = true },
    functions = { bold = true },
    variables = {},
    string = { italic = true },
  }
})

vim.cmd("colorscheme NeoSolarized")
vim.cmd("syntax enable")
