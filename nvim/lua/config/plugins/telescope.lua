local telescope = require("telescope")
local lga_actions = require("telescope-live-grep-args.actions")
local actions = require('telescope.actions')

-- Plugin setup
telescope.setup {
  defaults = {
    path_display = { "truncate" },
    hidden = true,
    mappings = {
      i = {
        ["<C-q>"] = actions.smart_send_to_qflist + actions.open_qflist,
      },
      n = {
        ["<C-e>"] = actions.delete_buffer,
        ["<C-q>"] = actions.smart_send_to_qflist + actions.open_qflist,
        ["<C-Down>"] = actions.cycle_history_next,
        ["<C-Up>"] = actions.cycle_history_prev,
      },
    },
  },
  extensions = {
    live_grep_args = {
      auto_quoting = true,
      mappings = {
        i = {
          -- Custom grep args mappings (optional)
        },
      },
    },
  },
}
telescope.load_extension("live_grep_args")

-- Keymaps (Lua version of your .vimrc mappings)
local keymap = vim.keymap.set
local opts = { noremap = true, silent = true }

keymap("n", "<leader>fr", "<cmd>Telescope resume<cr>", opts)
keymap("n", "<leader>ff", "<cmd>Telescope find_files<cr>", opts)
keymap("n", "<leader>fg", function()
  require("telescope").extensions.live_grep_args.live_grep_args()
end, opts)
keymap("n", "<leader>fb", "<cmd>Telescope buffers<cr>", opts)
keymap("n", "<leader>fh", "<cmd>Telescope help_tags<cr>", opts)
keymap("n", "<leader>fF", function()
  require("telescope.builtin").git_files({ default_text = vim.fn.expand("<cword>") })
end, opts)
keymap("n", "<leader>fG", function()
  require("telescope.builtin").live_grep({ default_text = vim.fn.expand("<cword>") })
end, opts)
