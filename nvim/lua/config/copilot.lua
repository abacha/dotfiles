require('copilot').setup({
  panel = {
    enabled = true,
    auto_refresh = true,
    keymap = {
      jump_prev = "[[",
      jump_next = "]]",
      accept = "<CR>",
      refresh = "gr",
      open = "<M-CR>"
    },
    layout = {
      position = "bottom", -- | top | left | right
      ratio = 0.4
    },
  },
  suggestion = {
    enabled = true,
    auto_trigger = true,
    hide_during_completion = true,
    debounce = 75,
    keymap = {
      accept = "<Tab>",
      accept_word = "<C-w>",
      accept_line = "<C-l>",
      next = "<M-]>",
      prev = "<M-[>",
      dismiss = "<C-]>",
    },
  },
})

require("CopilotChat").setup ({
  context = {
    enabled = true
  },
  mappings = {
    reset = {
      normal = "",
      insert = "<C-l>",
    },
  }
})
