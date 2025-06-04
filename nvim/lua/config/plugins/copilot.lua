require('copilot').setup({
  panel = { enabled = false, },
  -- suggestion = { enabled = false, }
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
