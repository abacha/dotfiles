-- Use vim defaults
vim.opt.compatible = false

-- Set leader key
vim.g.mapleader = ','

-- Set encoding
vim.opt.encoding = 'utf-8'
vim.opt.fileencoding = 'utf-8'


-- Commands
vim.cmd('filetype plugin indent on')
if vim.opt.t_Co:get() > 2 or vim.fn.has('gui_running') then
  vim.opt.hlsearch = true
end

vim.cmd([[
  autocmd BufWritePre * %s/\s\+$//e
  autocmd BufNewFile,BufRead *.slim setlocal filetype=slim
]])

-- Colors
vim.cmd('syntax enable')
vim.opt.t_Co = 256
vim.opt.background = 'dark'
vim.cmd('colorscheme solarized')

-- Folding
vim.opt.foldmethod = 'indent'
vim.opt.foldnestmax = 10
vim.opt.foldenable = false
vim.opt.foldlevel = 1
vim.cmd([[
  autocmd InsertEnter * if !exists('w:last_fdm') | let w:last_fdm=&foldmethod | setlocal foldmethod=manual | endif
  autocmd InsertLeave,WinLeave * if exists('w:last_fdm') | let &l:foldmethod=w:last_fdm | unlet w:last_fdm | endif
]])

-- Configs
vim.opt.tabstop = 2
vim.opt.softtabstop = 2
vim.opt.shiftwidth = 2
vim.opt.expandtab = true
vim.opt.smarttab = true
vim.opt.backspace = {'indent', 'eol', 'start'}
vim.opt.listchars = {tab = '▸ ', eol = '¬', trail = '·', precedes = '«', extends = '»'}
vim.opt.textwidth = 120
vim.opt.linebreak = true
vim.opt.showbreak = '…'
vim.opt.sidescroll = 8
vim.opt.scrolloff = 8
vim.opt.formatprg = 'par -TbgqRw80'
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
vim.opt.wildmode = {'list', 'longest'}
vim.opt.shortmess:append('atI')
vim.opt.timeoutlen = 500
vim.opt.wrap = true
vim.opt.wrapmargin = 120
vim.opt.visualbell = true
vim.opt.hidden = true
vim.opt.title = true
vim.opt.cc = '+1'
vim.opt.backupdir = {'~/.vim/backup', '~/tmp', '/var/tmp', '/tmp'}
vim.opt.directory = {'~/.vim/backup', '~/tmp', '/var/tmp', '/tmp'}
vim.opt.completeopt = {'menu', 'menuone', 'longest'}
vim.opt.pumheight = 10
vim.opt.wildignore:append({'*/.hg/*', '*/.svn/*', '*.o', 'moc_*.cpp', '*.exe', '*.qm', '.gitkeep', '.DS_Store'})

-- Toggle paste mode with <leader>p
vim.opt.pastetoggle = '<leader>p'
vim.cmd([[
  function! PasteCB()
    set paste
    set nopaste
  endfunction
]])

-- Save/quit typos
vim.cmd([[
  cab W w
  cab Q q
  cab Wq wq
  cab wQ wq
  cab WQ wq
  cab Bd bd
  cab Wa wa
  cab WA wa
  cab X x
]])

vim.cmd('autocmd CursorHold * checktime')

-- Keep line index when reopening a file
vim.cmd([[
  autocmd BufReadPost *
    \ if line("'\"") > 0 && line("'\"") <= line("$") |
    \   exe "normal g`\"" |
    \ endif
]])

-- Sudo to write
vim.cmd('cnoremap w!! w !sudo tee % >/dev/null')

-- Window management
vim.api.nvim_set_keymap('n', '<Up>', '<C-w>+', {noremap = true})
vim.api.nvim_set_keymap('n', '<Down>', '<C-w>-', {noremap = true})
vim.api.nvim_set_keymap('n', '<Left>', '<C-w>>', {noremap = true})
vim.api.nvim_set_keymap('n', '<Right>', '<C-w><', {noremap = true})
vim.api.nvim_set_keymap('n', '<C-j>', '<C-w>j', {noremap = true})
vim.api.nvim_set_keymap('n', '<C-k>', '<C-w>k', {noremap = true})
vim.api.nvim_set_keymap('n', '<C-h>', '<C-w>h', {noremap = true})
vim.api.nvim_set_keymap('n', '<C-l>', '<C-w>l', {noremap = true})

-- Functions
function OpenTestAlternate()
  local new_file = AlternateForCurrentFile()
  vim.cmd('vsp ' .. new_file)
end

function AlternateForCurrentFile()
  local current_file = vim.fn.expand('%')
  local new_file = current_file
  local in_spec = string.match(current_file, '^spec/') ~= nil
  local in_spec_lib = string.match(current_file, '^spec/lib/') ~= nil
  local going_to_spec = not in_spec

  if going_to_spec then
    if string.match(current_file, '^app/') ~= nil then
      new_file = string.gsub(new_file, '^app/', '')
      new_file = string.gsub(new_file, '%.rb$', '_spec.rb')
      new_file = 'spec/' .. new_file
    else
      new_file = string.gsub(new_file, '^lib/', '')
      new_file = string.gsub(new_file, '%.rb$', '_spec.rb')
      new_file = 'spec/lib/' .. new_file
    end
  else
    new_file = string.gsub(new_file, '_spec%.rb$', '.rb')
    if in_spec_lib then
      new_file = string.gsub(new_file, '^spec/lib/', 'lib/')
    else
      new_file = string.gsub(new_file, '^spec/', 'app/')
    end
  end

  return new_file
end

vim.api.nvim_set_keymap('n', '<leader>.', ':lua OpenTestAlternate()<CR>', {noremap = true})

-- Plugins
vim.g.gist_open_browser_after_post = 1
vim.g.gist_post_private = 1
vim.g.gist_detect_filetype = 1
vim.g.gist_clip_command = 'xclip -selection clipboard'
vim.g.github_token = os.getenv('GITHUB_TOKEN')

vim.api.nvim_set_keymap('n', '<leader>ff', '<cmd>Telescope find_files<cr>', {noremap = true})
vim.api.nvim_set_keymap('n', '<leader>fg', ':lua require("telescope").extensions.live_grep_args.live_grep_args()<cr>', {noremap = true})
vim.api.nvim_set_keymap('n', '<leader>fb', '<cmd>Telescope buffers<cr>', {noremap = true})
vim.api.nvim_set_keymap('n', '<leader>fh', '<cmd>Telescope help_tags<cr>', {noremap = true})
vim.api.nvim_set_keymap('n', '<leader>fF', ':execute "Telescope find_files default_text=" .. vim.fn.expand("<cword>")<cr>', {noremap = true})
vim.api.nvim_set_keymap('n', '<leader>fG', ':execute "Telescope live_grep default_text=" .. vim.fn.expand("<cword>")<cr>', {noremap = true})

vim.cmd('autocmd FileType nerdtree cnoreabbrev <buffer> bd <nop>')

-- KeyBinds
vim.api.nvim_set_keymap('n', '<leader>v', ':edit ~/.vimrc<CR>', {noremap = true})
vim.api.nvim_set_keymap('n', '<leader>sv', ':source $MYVIMRC<CR>', {noremap = true})
vim.api.nvim_set_keymap('n', '<leader>c', ':bufdo :bd<CR>', {noremap = true})
vim.api.nvim_set_keymap('n', '<Tab>', '<c-w>w', {noremap = true})
vim.api.nvim_set_keymap('n', '<C-n>', ':NERDTreeToggle<CR>', {noremap = true})
vim.api.nvim_set_keymap('n', '<F3>', ':tabprevious<CR>', {noremap = true})
vim.api.nvim_set_keymap('n', '<F4>', ':tabnext<CR>', {noremap = true})
vim.api.nvim_set_keymap('v', '<C-y>', '"+y', {noremap = true})
vim.api.nvim_set_keymap('n', '<leader>gc', ':CopilotChat<CR>', {noremap = true})
vim.cmd('cnoremap %% <C-R>=expand("%:h")."/"<CR>')
vim.cmd('cnoremap cb 1,100bdelete')
vim.cmd('cnoremap %f <C-R>=expand("%")<CR>')
vim.api.nvim_set_keymap('n', '<cr>', ':silent! nohlsearch<cr>|silent! redraw!', {noremap = true})
vim.api.nvim_set_keymap('n', '<leader><leader>', '^', {noremap = true})
vim.api.nvim_set_keymap('n', '\\', '$', {noremap = true})
vim.api.nvim_set_keymap('n', '<leader>ea', ':b#<CR>', {noremap = true})
vim.api.nvim_set_keymap('n', '<space>', 'za', {noremap = true})
vim.api.nvim_set_keymap('n', '<leader>l', ':set list!<CR>', {noremap = true})
vim.api.nvim_set_keymap('n', '<leader>e', ':edit %%', {noremap = true})
vim.api.nvim_set_keymap('i', 'jj', '<esc>', {noremap = true})
vim.api.nvim_set_keymap('i', '<C-i>', 'copilot#Accept("\\<CR>")', {silent = true, expr = true, script = true})
