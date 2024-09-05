print("Loading autocommands.lua")

local uv = vim.loop

print("Assigned vim.loop to uv")

vim.api.nvim_create_autocmd('VimEnter', {
    callback = function()
        print("VimEnter event triggered")
        if vim.env.TMUX_PLUGIN_MANAGER_PATH then
            print("TMUX_PLUGIN_MANAGER_PATH is set to " .. vim.env.TMUX_PLUGIN_MANAGER_PATH)
            uv.spawn(vim.env.TMUX_PLUGIN_MANAGER_PATH .. '/tmux-window-name/scripts/rename_session_windows.py', {}, function(code, signal)
                print("Process exited with code " .. code .. " and signal " .. signal)
            end)
        else
            print("TMUX_PLUGIN_MANAGER_PATH is not set")
        end
    end,
})

print("Finished setting up autocommand")
