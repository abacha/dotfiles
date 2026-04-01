# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

Personal dotfiles repository for a WSL-based development environment. Manages shell, editor, terminal multiplexer, git, and window manager configurations.

## Setup

```bash
# Full environment setup
./setup.sh

# Run a specific setup function
./setup.sh <function_name>
# Available functions: install_basic_packages, install_extra_packages,
# setup_docker, setup_asdf, setup_node, setup_neovim, setup_ruby,
# setup_python, setup_uv, setup_ai_clis, setup_zsh, create_symlinks,
# setup_secrets, setup_ai_config, setup_tmux, setup_tmuxinator, setup_wsl
```

`setup.sh` installs packages, sets up tools (Node.js 25 via asdf, uv, Codex, Gemini, Claude Code, Oh-My-Zsh, Neovim/packer, TPM), and symlinks dotfiles to `$HOME`.

## Architecture

**Dotfiles** (symlinked to `$HOME` by `create_symlinks`):
- `.zshrc` — Zsh config: Oh-My-Zsh, Powerlevel10k theme, aliases, asdf/pnpm/gcloud integration
- `.tmux.conf` — Tmux config: Ctrl-A prefix, vi-mode, TPM plugins, hjkl pane navigation
- `.gitconfig` — Git aliases (`h`, `l`, `s`, `amend`, `ap`, `co`, `dc`, `fp`, `rbm`), rebase-by-default, Neovim as merge tool
- `.ackrc` — Search config with language definitions and ignore patterns
- `.inputrc` — Vi editing mode for readline
- `.pryrc` / `.gemrc` — Ruby REPL and gem settings
- `.tool-versions` — asdf version specs (Node 25.7.0, Ruby 3.3.8)

**Neovim** (`nvim/`):
- Lua-based config. Entry: `nvim/init.lua` → `nvim/lua/config/` modules
- Plugin manager: packer.nvim (`lua/config/plugins.lua`)
- Leader key: `,`
- Key modules: `options.lua`, `mappings.lua`, `autocmds.lua`
- Plugin configs in `lua/config/plugins/` (LSP, telescope, nvim-cmp, treesitter, copilot, gitsigns, vim-test)

**WSL/Windows** (`wsl/`):
- `glazewm_config.yaml` — Tiling window manager (Alt+hjkl nav, 9 named workspaces, app routing rules)
- `zebar_config.yaml` — Status bar for GlazeWM
- `install.sh` — Claude Code CLI installer with platform detection and checksum verification

**Tmuxinator** (`tmuxinator/`):
- Pre-defined tmux session layouts for development (hubstaff, bigbang)

**Agent Guidelines** (`agents/`):
- Project-specific AI assistant instructions (hubstaff=Rails/Vue, climate-risk-analysis=Python/Flask, chess_memory_tester=React/Express)
- `preferences.md` — Global agent behavior: routine commands allowed without approval, destructive actions (deletions, commits, resets) require approval

## Key Conventions

- Git workflow: rebase-based, autosquash enabled, conventional commits
- Version management via asdf
- Docker/docker-compose for project development
- Neovim with LSP + Copilot as primary editor
