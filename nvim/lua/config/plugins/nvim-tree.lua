require('nvim-tree').setup{
  renderer = {
    icons = {
      show = {
        file = false,
        folder = false,
        folder_arrow = true,
        git = true,
      },
      glyphs = {
        folder = {
          arrow_closed = "📁",
          arrow_open = "📂",
        },
        git = {
          unstaged = "✏️",
          staged = "✅",
          unmerged = "🔴",
          renamed = "➡️",
          untracked = "❓",
          deleted = "❌",
          ignored = "🙈",
        },
      },
    },
  },
}
