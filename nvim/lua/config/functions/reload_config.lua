local function reload_config()
 for name,_ in pairs(package.loaded) do
   if name:match('^config') then
     package.loaded[name] = nil
   end
 end
 dofile(vim.env.MYVIMRC)
end, {})
