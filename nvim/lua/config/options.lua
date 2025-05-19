vim.g.mapleader = ","
vim.opt.encoding = "utf-8"
vim.opt.fileencoding = "utf-8"
vim.opt.backupdir = { "~/.vim/backup", "~/tmp", "/var/tmp", "/tmp" }
vim.opt.directory = { "~/.vim/backup", "~/tmp", "/var/tmp", "/tmp" }
vim.opt.backspace = { "indent", "eol", "start" }
vim.opt.textwidth = 120
vim.opt.linebreak = true
vim.opt.showbreak = "…"
vim.opt.sidescroll = 8
vim.opt.scrolloff = 8
vim.opt.autoindent = true
vim.opt.smartindent = true
vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.incsearch = true
vim.opt.showmatch = true
vim.opt.matchtime = 2
vim.opt.ruler = true
vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.autoread = true
vim.opt.wildmenu = true
vim.opt.wildmode = { "list", "longest" }
vim.opt.shortmess:append("atI")
vim.opt.timeoutlen = 500
vim.opt.wrap = true
vim.opt.wrapmargin = 120
vim.opt.visualbell = true
vim.opt.hidden = true
vim.opt.title = true
vim.opt.colorcolumn = "+1"
vim.opt.statusline = "%F%m%r%h%w [%l/%L] [%v]"
vim.opt.completeopt = { "menu", "menuone", "longest" }
vim.opt.pumheight = 10
vim.opt.wildignore:append({
  "*/.hg/*", "*/.svn/*", "*.o", "moc_*.cpp", "*.exe", "*.qm", ".gitkeep", ".DS_Store"
})
vim.opt.listchars = {
  tab = "▸ ",
  eol = "¬",
  trail = "·",
  precedes = "«",
  extends = "»"
}
vim.opt.expandtab = true
vim.opt.tabstop = 2
vim.opt.softtabstop = 2
vim.opt.shiftwidth = 2
vim.opt.smarttab = true
vim.opt.formatprg = "par -TbgqRw80"
vim.opt.list = true

-- Colors
vim.opt.background = "dark"
vim.cmd("colorscheme solarized")
vim.cmd("syntax enable")
