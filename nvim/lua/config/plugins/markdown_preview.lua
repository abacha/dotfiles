vim.g.mkdp_filetypes = { 'markdown' }
vim.g.mkdp_auto_start = 0
vim.g.mkdp_auto_close = 1
vim.g.mkdp_echo_preview_url = 1
vim.g.mkdp_open_to_the_world = 0

-- SSH-aware configuration for remote nodes
if vim.env.SSH_CONNECTION then
  vim.g.mkdp_open_to_the_world = 1
  vim.g.mkdp_browser = '' -- Don't try to open a browser remotely
  vim.g.mkdp_port = '9097' -- Use a non-common port
elseif vim.fn.has('wsl') == 1 then
  -- Use wslview in WSL to open the browser in Windows
  vim.g.mkdp_browser = 'wslview'
end
