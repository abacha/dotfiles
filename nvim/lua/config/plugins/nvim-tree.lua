require('nvim-tree').setup{
  filters = {
    dotfiles = false,
    custom = {
      "^\\.git$",
      "^\\.mypy_cache$",
      "^\\.ruff_cache$",
      "^\\.pytest_cache$",
      "^__pycache__$",
      "^\\.venv$",
      "^venv$",
      "^\\.env$",
      "^node_modules$",
      "\\.pyc$",
      "^__init__\\.py$",
    },
  },
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
