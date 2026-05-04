# Graph Report - .  (2026-05-04)

## Corpus Check
- Corpus is ~18,649 words - fits in a single context window. You may not need a graph.

## Summary
- 116 nodes · 98 edges · 47 communities (30 shown, 17 thin omitted)
- Extraction: 83% EXTRACTED · 17% INFERRED · 0% AMBIGUOUS · INFERRED: 17 edges (avg confidence: 0.81)
- Token cost: 150,222 input · 0 output

## Community Hubs (Navigation)
- [[_COMMUNITY_Neovim Editor Configuration|Neovim Editor Configuration]]
- [[_COMMUNITY_Statsig Feature Flags|Statsig Feature Flags]]
- [[_COMMUNITY_Dotfiles & Git Integration|Dotfiles & Git Integration]]
- [[_COMMUNITY_AI Coding Guidelines|AI Coding Guidelines]]
- [[_COMMUNITY_Statsig Entity CRUD|Statsig Entity CRUD]]
- [[_COMMUNITY_Rails Test Navigation|Rails Test Navigation]]
- [[_COMMUNITY_Claude Auth & Caching|Claude Auth & Caching]]
- [[_COMMUNITY_AIOMA Project|AIOMA Project]]
- [[_COMMUNITY_Nexus Recall System|Nexus Recall System]]
- [[_COMMUNITY_Assimilator Finance|Assimilator Finance]]
- [[_COMMUNITY_WSL Window Manager|WSL Window Manager]]
- [[_COMMUNITY_Codex Auth|Codex Auth]]
- [[_COMMUNITY_AI Usage Tracking|AI Usage Tracking]]
- [[_COMMUNITY_Chess Memory Tester|Chess Memory Tester]]
- [[_COMMUNITY_Hubstaff Statsig|Hubstaff Statsig]]
- [[_COMMUNITY_Tiao WhatsApp Bot|Tiao WhatsApp Bot]]
- [[_COMMUNITY_Trag Web Frontend|Trag Web Frontend]]
- [[_COMMUNITY_Trag Backend API|Trag Backend API]]
- [[_COMMUNITY_Statsig CLI|Statsig CLI]]
- [[_COMMUNITY_Plugin Configs|Plugin Configs]]
- [[_COMMUNITY_Packer Manager|Packer Manager]]
- [[_COMMUNITY_OAuth Tokens|OAuth Tokens]]
- [[_COMMUNITY_CMP Sources|CMP Sources]]
- [[_COMMUNITY_Climate Risk Analysis|Climate Risk Analysis]]
- [[_COMMUNITY_Statsig CLI Tool|Statsig CLI Tool]]
- [[_COMMUNITY_Tmuxinator Sessions|Tmuxinator Sessions]]

## God Nodes (most connected - your core abstractions)
1. `StatsigManager` - 15 edges
2. `Packer plugin definition` - 8 edges
3. `Keymappings configuration` - 6 edges
4. `AGENTS.md - Global Implementation Guidelines` - 5 edges
5. `nvim-tree plugin setup` - 4 edges
6. `Copilot and CopilotChat setup` - 4 edges
7. `Dotfiles Neovim Configuration` - 4 edges
8. `StatsigManager class` - 3 edges
9. `OpenTestAlternate function` - 3 edges
10. `rails_alternate_for_current_file()` - 2 edges

## Surprising Connections (you probably didn't know these)
- `Dotfiles Neovim Configuration` --conceptually_related_to--> `Gitsigns Plugin Setup`  [INFERRED]
  ai/constitutions/dotfiles.md → nvim/lua/config/plugins/gitsigns.lua
- `Tmuxinator Editor Session` --conceptually_related_to--> `Gitsigns Plugin Setup`  [INFERRED]
  tmuxinator/editor.yml → nvim/lua/config/plugins/gitsigns.lua
- `Dotfiles Neovim Configuration` --conceptually_related_to--> `Telescope Plugin Configuration`  [INFERRED]
  ai/constitutions/dotfiles.md → nvim/lua/config/plugins/telescope.lua
- `Dotfiles Neovim Configuration` --conceptually_related_to--> `NVim-CMP Completion Setup`  [INFERRED]
  ai/constitutions/dotfiles.md → nvim/lua/config/plugins/nvim-cmp.lua
- `Tmuxinator Hubstaff-2 Session` --conceptually_related_to--> `AGENTS.md - Global Implementation Guidelines`  [INFERRED]
  tmuxinator/hubstaff-2.yml → ai/constitutions/global-rules.md

## Hyperedges (group relationships)
- **Neovim Completion Ecosystem** — nvim_lsp, nvim_copilot, nvim_lualine [INFERRED 0.75]
- **AI Usage Tracking and Caching Flow** — aiusagetracker_check_claude_auth, aiusagetracker_do_check_claude_auth, aiusagetracker_cache_management [INFERRED 0.85]
- **Neovim Development Workflow Setup** — nvim_rails_test_alternate, nvim_mappings, nvim_reload_config [INFERRED 0.80]
- **Neovim Plugin Configuration Ecosystem** — gitsigns_setup, telescope_setup, vim_test_docker, nvim_cmp_setup [INFERRED 0.85]
- **Project-Specific AI Constitutions** — hubstaff_server_constitution, tiao_constitution, chess_memory_tester_constitution, aioma_constitution, nexus_recall_constitution, trag_web_constitution, trag_backend_constitution, assimilator_constitution [INFERRED 0.80]
- **WSL Development Environment Stack** — zebar_status_bar, glazewm_window_manager, tmuxinator_editor, tmuxinator_hubstaff2 [INFERRED 0.75]

## Communities (47 total, 17 thin omitted)

### Community 0 - "Neovim Editor Configuration"
Cohesion: 0.15
Nodes (18): Neovim autocommands, NeoSolarized colorscheme setup, Copilot and CopilotChat setup, Fold configuration, LSP configuration, LSP Capabilities Integration, Lualine statusline setup, Keymappings configuration (+10 more)

### Community 2 - "Dotfiles & Git Integration"
Cohesion: 0.25
Nodes (8): Dotfiles Repository CLAUDE.md, Dotfiles Neovim Configuration, Gitsigns Plugin Setup, NVim-CMP Completion Setup, Telescope Keymaps, Telescope Plugin Configuration, Tmuxinator Editor Session, Vim-Test Docker Transformation

### Community 3 - "AI Coding Guidelines"
Cohesion: 0.4
Nodes (6): Docker-First Hard Constraint, AGENTS.md - Global Implementation Guidelines, Karpathy-Style Coding Principles, Nexus Homelab Infrastructure, Operational Rules for Implementation, Tmuxinator Hubstaff-2 Session

### Community 4 - "Statsig Entity CRUD"
Cohesion: 0.67
Nodes (4): StatsigManager class, clone_entity method, create_entity method, list_entities method

### Community 6 - "Claude Auth & Caching"
Cohesion: 0.67
Nodes (3): Cache Management with TTL, check_claude_auth function, do_check_claude_auth function

### Community 7 - "AIOMA Project"
Cohesion: 0.67
Nodes (3): AIOMA API Contract, AIOMA Project Architecture, AIOMA Project Constitution

### Community 8 - "Nexus Recall System"
Cohesion: 0.67
Nodes (3): Nexus Recall Layered Architecture, Nexus Recall Agent Guide, Nexus Recall Layer Rules

### Community 9 - "Assimilator Finance"
Cohesion: 1.0
Nodes (3): Assimilator Architecture, Assimilator Personal Finance Platform, Assimilator Domain Model

### Community 10 - "WSL Window Manager"
Cohesion: 0.67
Nodes (3): GlazeWM Window Manager Configuration, GlazeWM Workspace Layout, Zebar Status Bar Configuration

## Knowledge Gaps
- **39 isolated node(s):** `Statsig Manager CLI`, `create_entity method`, `Neovim options configuration`, `NeoSolarized colorscheme setup`, `Markdown preview configuration` (+34 more)
  These have ≤1 connection - possible missing edges or undocumented components.
- **17 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **What connects `Statsig Manager CLI`, `create_entity method`, `Neovim options configuration` to the rest of the system?**
  _39 weakly-connected nodes found - possible documentation gaps or missing edges._