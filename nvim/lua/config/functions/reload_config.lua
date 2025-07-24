local function reload_config()
  for name,_ in pairs(package.loaded) do
    if name:match('^config%.functions') or name:match('^config%.settings') then
      package.loaded[name] = nil
    end
  end
  vim.cmd('source ' .. vim.fn.stdpath('config') .. '/init.lua')
end

_G.ReloadConfig = reload_config
