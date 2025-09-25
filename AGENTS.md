AGENTS quick-start for vscpanel.nvim

Build/lint/test
- Dev shell: use Nix for reproducible tools.
  - Enter shell: nix develop
  - Minimal Neovim runtime for manual testing: nvim-dev (custom script in Nix shell)
  - Alternative: nvim -u tests/minimal_init.lua --cmd "set rtp+=$(pwd)"
- Formatting:
  - Nix files: alejandra (nix fmt)
  - Lua: stylua (convention; install if missing) -> stylua .
- Linting:
  - Lua: luacheck (available in Nix shell) -> just lint
- Tests: comprehensive automated test suite using plenary.nvim:
  - Run all tests: just run-tests or just check (includes tests + lint + docs + health)
  - Tests cover: panel creation, state management, config validation, keybinds, winbar, terminal menu, positioning, and more
  - Health check: just health or :checkhealth vscpanel
- Documentation:
  - Generate docs: just gen-docs or just docs (includes validation)
  - Test docs: just test-docs
- Development workflow: use just check for full validation (tests + lint + docs + health)
- Manual test entry points:
  - :lua require('vscpanel').setup()
  - :TogglePanel, :TogglePanelSize, :ShowTerminalMenu, :PanelTermHelp commands

Code style guidelines
- Language: Lua 5.1+ (Neovim). Prefer local modules; avoid globals (use _G only for UI callbacks already exposed).
- Imports: use require('vscpanel.<module>'); cache in locals; avoid side effects at top-level.
- Formatting: 2-space indent; single quotes for strings unless escaping; keep lines <= 120 cols; run stylua.
- Types/docs: add EmmyLua annotations (--- @param, --- @return) and succinct docstrings for public APIs.
- Naming: modules and tables in lower_snake_case; exported module table as M; constants UPPER_SNAKE_CASE; user options in lower_snake_case.
- Errors: validate inputs; fail fast with error for programmer errors (e.g., wrong types); use pcall for Neovim API that can fail; user-facing issues via vim.notify with proper level.
- Neovim API: guard window/buffer validity (vim.api.nvim_*_is_valid); avoid hard failures in autocmd/keymaps; schedule/defer when needed to avoid focus/layout churn.
- State: keep minimal state in module (M.state) and scope per-tab in vim.t when appropriate; never store window ids without validity checks.
- Performance: avoid O(n^2) scans in hot paths; prefer bufwinid, winrestcmd, and tab-scoped state; avoid polling.

Architecture overview
- Main modules: init.lua (setup/API), panel.lua (window management), state.lua (terminal/window state), config.lua (options)
- Supporting modules: terminal.lua (terminal creation), winbar.lua (UI controls), menu.lua (terminal picker), commands.lua (ex-commands), keybinds.lua (key mappings), help.lua (help system)
- Features: toggleable terminal panel, maximize/minimize, multi-terminal support, configurable positioning (bottom/top/left/right), dynamic winbar, terminal menu/picker
- Plugin structure: plugin/vscpanel.lua (entry point), lua/vscpanel/ (implementation), doc/vscpanel.txt (help), tests/ (comprehensive test suite)

Current status & TODOs
- Core functionality: stable and well-tested
- Multi-terminal view: partially implemented, needs completion of terminal registration and picker UI
- Keybind coverage: mouse actions need keyboard alternatives
- Code cleanup: ongoing file-by-file review and optimization

Cursor/Copilot rules
- No .cursor/rules or .cursorrules found; no .github/copilot-instructions.md present. If added later, reflect them here.
