local function rails_alternate_for_current_file()
  local file = vim.fn.expand("%")
  local new_file = file
  local in_spec = file:match("^spec/")
  local in_spec_lib = file:match("^spec/lib/")
  local in_spec_db = file:match("^spec/db/")

  if not in_spec then
    new_file = file:gsub("^app/", ""):gsub("%.rb$", "_spec.rb")
    return "spec/" .. new_file
  else
    new_file = new_file:gsub("_spec%.rb$", ".rb")
    if in_spec_lib then return new_file:gsub("^spec/lib/", "lib/")
    elseif in_spec_db then return new_file:gsub("^spec/db/", "db/")
    else return new_file:gsub("^spec/", "app/") end
  end
end

function OpenTestAlternate()
  vim.cmd("vsp " .. rails_alternate_for_current_file())
end

vim.keymap.set("n", "<leader>.", ":lua OpenTestAlternate()<cr>", { silent = true })
