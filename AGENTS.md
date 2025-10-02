# AGENTS file for vscpanel.nvim

This file provides comprehensive guidance for AI coding assistants and human developers working on vscpanel.nvim.

## Project Overview

vscpanel.nvim is a VSCode-style integrated terminal panel for Neovim with advanced multi-terminal management. The plugin provides a persistent panel window that can host multiple terminal instances with tab-based switching, dynamic UI controls, and flexible positioning.

### Key Features
- Multi-terminal management with visual tabs
- VSCode-style panel with dynamic winbar controls
- State management using reducer pattern
- Flexible panel positioning (bottom/top/left/right)
- Auto-insert mode for seamless terminal interaction
- Terminal renaming and shell selection
- Extensive test coverage with plenary.nvim

## Architecture

### Core System Modules

#### `vscpanel.init`
Main entry point and public API. Provides:
- `setup(opts)` - Initialize plugin with user configuration
- `ensure_insert(win)` - Ensure terminal is in insert mode
- `show_help()` - Display help window
- `max_toggle()` - Toggle panel maximize/minimize state
- `open_terminal_view()` - Open terminal view
- `open_problems_view()` - Open problems view (planned)

#### `vscpanel.state`
Centralized state management using a **reducer pattern**. Critical concepts:
- **State structure**: Single source of truth for all plugin state
- **Actions**: Pure functions that modify state (`actions.add_terminal`, `actions.set_active_terminal`, etc.)
- **Dispatcher**: `M.dispatch(action_name, ...)` safely executes actions with error handling
- **Validation**: All state changes validate buffers/windows before modification
- **State object** contains:
  - `window_id` - Main panel window
  - `terminals[]` - Array of terminal objects with buffer, label, shell
  - `active_terminal` - Currently focused terminal
  - `maximized` - Panel maximize state
  - `tabs_visible` - Whether tabs are displayed
  - `tabs_window`, `tabs_buffer` - Tab window references

Example state modification:
```lua
-- Always use dispatch for state changes
state.dispatch("add_terminal", { buffer = buf, label = "zsh", shell = "/bin/zsh" })
state.dispatch("set_active_terminal", buf)
state.dispatch("remove_terminal", buf)
```

#### `vscpanel.panel`
Panel window lifecycle and layout management. Handles:
- Creating/destroying panel windows with proper splits
- Position management (bottom, top, left, right)
- Window size calculations
- Maximize/restore functionality
- View switching (terminal, problems)
- State restoration on panel reopen

#### `vscpanel.config`
Configuration validation and normalization:
- Validates user options against schema
- Provides sensible defaults
- Normalizes position and size values
- Manages icon configuration
- Type checking with EmmyLua annotations

### UI Components

#### `vscpanel.winbar`
Dynamic winbar with clickable controls. Uses global namespace for callbacks:
- Registers functions in `_G[constants.NAMESPACE]` for winbar click handlers
- Builds winbar string with icons and Vim's `%@` click syntax
- Updates based on `User WinbarUpdate` autocmd
- Icons: new terminal, launch profile, help, hide panel, toggle size

#### `vscpanel.views.terminal.tabs`
Multi-terminal tab interface:
- Shows vertical split with terminal list when multiple terminals exist
- Blue indicator (●) marks active terminal
- Keybindings: `<Enter>` switch, `<LeftMouse>` click, `d` delete
- Auto-hides when only one terminal remains
- Refreshes on terminal add/remove/switch

#### `vscpanel.views.terminal.context_menu`
Shell picker for terminal creation:
- Reads available shells from `/etc/shells`
- Displays floating window with shell options
- Highlights default shell
- Creates new terminal with selected shell

### View System

#### `vscpanel.views`
View registry and management:
```lua
views = {
  TERMINAL = 1,
  PROBLEMS = 2,
}
```

#### `vscpanel.views.terminal`
Terminal creation and lifecycle:
- `create_terminal(win, shell)` - Create new terminal with jobstart
- `close_terminal(line_number)` - Close terminal by index
- `handle_terminal_removal(buf)` - Cleanup on TermClose
- Registers buffer-local keybindings
- Manages terminal state transitions
- Triggers tab refresh and winbar updates

#### `vscpanel.views.problems`
Problems view (planned feature for diagnostics display)

### Support Modules

#### `vscpanel.commands`
User command registration:
- `:TogglePanel` - Show/hide panel
- `:TogglePanelSize` - Maximize/minimize
- `:ShowTerminalMenu` - Shell picker
- `:PanelTermHelp` - Help window

#### `vscpanel.keybinds`
Buffer-local keybinding setup:
- `<C-H>` - Show help
- `<C-N>` - Open shell picker
- `<C-Space>` - Toggle maximize
- Sets up auto-insert autocmds for terminal buffers

#### `vscpanel.help`
Help system with key reference window

#### `vscpanel.constants`
Shared constants:
- `AUGROUP_NAME = "panelnvim"` - Autocmd group name
- `NAMESPACE = "vscpanel_winbar"` - Global namespace for winbar callbacks

#### `vscpanel.health`
Neovim health check implementation

## Development Environment

### Nix Development Shell
The repo uses Nix flakes for reproducible development:
```bash
# Enter development environment
nix develop

# Run minimal Neovim with plugin loaded
nvim-dev

# Format Nix files
nix fmt  # Uses alejandra
```

### Dependencies
- Neovim 0.8.0+
- plenary.nvim (for testing)
- luacheck (for linting)
- stylua (for formatting)
- act (optional, for local CI)

## Code Style Guidelines

### Language & Formatting
- **Language**: Lua 5.1+ (Neovim compatibility)
- **Indentation**: 2 spaces (no tabs)
- **Quotes**: Single quotes for strings (unless escaping needed)
- **Line length**: Maximum 120 characters
- **Formatter**: Run `stylua .` before committing

### Module Structure
```lua
local M = {}

-- Private helper at top
local function helper()
  -- ...
end

--- Public function with EmmyLua docs
--- @param param_name type Description
--- @return return_type Description
function M.public_function(param_name)
  -- Implementation
end

return M
```

### Naming Conventions
- **Modules/tables**: `lower_snake_case`
- **Exported module table**: `M`
- **Constants**: `UPPER_SNAKE_CASE`
- **Local variables**: `lower_snake_case`
- **Private functions**: `local function name()`
- **User options**: `lower_snake_case`

### Imports & Dependencies
```lua
-- Cache requires in locals
local state = require("vscpanel.state")
local config = require("vscpanel.config")

-- Avoid side effects at module load
-- Prefer lazy loading in functions when possible
local function get_opts()
  return require("vscpanel").opts or require("vscpanel.config").defaults
end
```

### Documentation
Use EmmyLua annotations for all public APIs:
```lua
--- @class vscpanel.Terminal
--- @field buffer number Terminal buffer ID
--- @field label string Display label
--- @field shell string Shell command

--- Creates a new terminal
--- @param win number Window handle
--- @param shell? string Optional shell command
--- @return number buffer Terminal buffer ID
function M.create_terminal(win, shell)
  -- ...
end
```

### Error Handling

**Validation** - Fail fast for programmer errors:
```lua
if type(buffer_id) ~= "number" then
  error("buffer_id must be a number")
end
```

**Neovim API** - Use pcall for operations that can fail:
```lua
local ok, result = pcall(vim.api.nvim_win_set_config, win, config)
if not ok then
  vim.notify("Failed to configure window: " .. result, vim.log.levels.ERROR)
  return
end
```

**User-facing issues** - Use vim.notify with appropriate levels:
```lua
vim.notify("vscpanel.nvim: Failed to start terminal", vim.log.levels.ERROR)
vim.notify("Terminal already exists", vim.log.levels.WARN)
vim.notify("Panel opened", vim.log.levels.INFO)
```

### Neovim API Best Practices

**Always validate window/buffer IDs**:
```lua
if not (win and vim.api.nvim_win_is_valid(win)) then
  return
end

if not vim.api.nvim_buf_is_valid(buf) then
  return
end
```

**Avoid hard failures in autocmds/keymaps**:
```lua
vim.api.nvim_create_autocmd("TermClose", {
  callback = function(args)
    -- Guard against invalid state
    if not (args.buf and vim.api.nvim_buf_is_valid(args.buf)) then
      return
    end
    -- Safe to proceed
  end,
})
```

**Use scheduling to avoid focus/layout issues**:
```lua
vim.schedule(function()
  -- Deferred UI operations
end)
```

### State Management Patterns

**Centralized state** via reducer pattern:
```lua
-- BAD: Direct state modification
state.terminals[1] = terminal

-- GOOD: Use dispatch
state.dispatch("add_terminal", terminal)
```

**Never store window IDs without validation**:
```lua
-- BAD: Storing without checking
self.win = win

-- GOOD: Validate first
actions.set_window = function(window_id)
  if not validate_window(window_id) then
    return false, "Invalid window ID"
  end
  state.window_id = window_id
  return true
end
```

**Minimize module-level state**:
- Keep state in `M.state` table
- Use tab-scoped state (`vim.t`) when appropriate
- Clear state in cleanup functions

### Performance Considerations

- **Avoid O(n²) operations** in hot paths (tabs refresh, winbar updates)
- **Prefer Neovim APIs**: Use `vim.fn.bufwinid()`, `vim.fn.winrestcmd()`
- **Cache lookups**: Don't repeatedly require() or search arrays
- **No polling**: Use autocmds and events instead of timers

## Testing

### Framework & Structure
- **Testing framework**: plenary.nvim
- **Test location**: `tests/*_spec.lua`
- **Minimal init**: `tests/minimal_init.lua`
- **Test utilities**: `tests/utils.lua` (cleanup helpers)

### Running Tests

```bash
# Run all tests and checks
just check

# Run only unit tests
just run-unit-tests

# Run specific test file
nvim --headless -u tests/minimal_init.lua \
  -c "lua require('plenary.busted').run('tests/state_spec.lua')" \
  -c "qa!"

# Run GitHub workflow locally (requires act)
just run-workflow

# Run linting
just lint

# Generate and test documentation
just docs

# Run health check
just health
```

### Test Coverage Areas
- Panel creation, positioning, and lifecycle
- State management (all actions)
- Terminal creation, switching, deletion
- Configuration validation
- Multi-terminal tabs functionality
- Keybinding setup
- Winbar updates
- Auto-insert mode
- Error handling and edge cases

### Writing Tests

**Structure**:
```lua
local assert = require("luassert")
local vscpanel = require("vscpanel")

describe("feature name", function()
  before_each(function()
    -- Clean state before each test
    local state = require("vscpanel.state")
    state.dispatch("clear_window")
    state.dispatch("clear_terminals")
    state.dispatch("set_active_terminal", nil)
  end)

  it("does something specific", function()
    -- Arrange
    vscpanel.setup({})

    -- Act
    local result = some_function()

    -- Assert
    assert.are.equal(expected, result)
  end)
end)
```

**Best practices**:
- Clean state in `before_each()` hooks
- Use descriptive test names
- Test both success and failure cases
- Use `vim.wait()` for async operations
- Test window/buffer cleanup

## Common Development Patterns

### Adding a New State Action

1. **Define the action in `state.lua`**:
```lua
--- @param new_value string
--- @return boolean result
--- @return string? error_msg
actions.set_something = function(new_value)
  if not validate_something(new_value) then
    return false, "Invalid value"
  end

  state.something = new_value
  return true
end
```

2. **Use via dispatch**:
```lua
state.dispatch("set_something", "new_value")
```

3. **Add getter if needed**:
```lua
function M.get_something()
  return state.something
end
```

### Adding a Winbar Button

1. **Add global callback in `winbar.lua`**:
```lua
_G[constants.NAMESPACE].my_action = function()
  -- Your action
end
```

2. **Build icon string**:
```lua
local function my_icon()
  local opts = get_opts()
  return table.concat({
    "%@v:lua.",
    constants.NAMESPACE,
    ".my_action@",
    opts.icons.my_icon,
    "%X",
  })
end
```

3. **Add to winbar string**:
```lua
function M.update()
  -- Add to winbar construction
end
```

### Creating a New View

1. **Add view constant in `views/init.lua`**:
```lua
views = {
  TERMINAL = 1,
  PROBLEMS = 2,
  MY_VIEW = 3,  -- New view
}
```

2. **Create view module `views/my_view/init.lua`**:
```lua
local M = {}

function M.setup()
  -- Initialize view
end

function M.open(win)
  -- Display view content
end

return M
```

3. **Integrate in `panel.lua`**'s `toggle_panel()`:
```lua
elseif active_view == views.views.MY_VIEW then
  require("vscpanel.views.my_view").open(new_win)
end
```

### Adding a Command

Add to `commands.lua`:
```lua
{
  name = "MyCommand",
  opts = {
    desc = "Description of command",
  },
  command = function()
    require("vscpanel.my_module").do_something()
  end,
},
```

## Project File Structure

```
vscpanel.nvim/
├── lua/vscpanel/
│   ├── init.lua              # Main setup and public API
│   ├── state.lua             # State management (reducer pattern)
│   ├── panel.lua             # Panel window management
│   ├── config.lua            # Configuration handling
│   ├── commands.lua          # Ex-command definitions
│   ├── keybinds.lua          # Buffer-local keybindings
│   ├── winbar.lua            # Dynamic winbar controls
│   ├── help.lua              # Help system
│   ├── health.lua            # Health check
│   ├── constants.lua         # Shared constants
│   └── views/
│       ├── init.lua          # View registry
│       ├── terminal/
│       │   ├── init.lua      # Terminal creation/management
│       │   ├── tabs.lua      # Multi-terminal tabs UI
│       │   └── context_menu.lua  # Shell picker
│       └── problems/
│           └── init.lua      # Problems view (planned)
├── plugin/
│   └── vscpanel.lua          # Plugin entry point
├── doc/
│   └── vscpanel.txt          # Help documentation
├── tests/
│   ├── minimal_init.lua      # Test configuration
│   ├── utils.lua             # Test utilities
│   └── *_spec.lua            # Test files
├── flake.nix                 # Nix development environment
├── justfile                  # Development commands
├── CONTRIBUTING.md           # Contribution guidelines
├── README.md                 # User documentation
└── AGENTS.md                 # This file
```

## Key Architectural Decisions

### Why Reducer Pattern for State?
- Single source of truth prevents inconsistencies
- Actions are testable in isolation
- Validation happens in one place
- Easy to add logging/debugging
- Safe concurrent modifications via dispatch

### Why Global Namespace for Winbar?
- Vim's `%@` click syntax requires global functions
- Centralized in one namespace to avoid pollution
- Clear separation between UI and logic

### Why Buffer-Local Keybindings?
- Only active in panel terminals
- Don't interfere with user's global bindings
- Easy cleanup when terminal closes
- Context-appropriate behavior

### Why Auto-Insert Mode?
- Matches VSCode terminal behavior
- Reduces friction for terminal interaction
- Configurable via BufEnter/WinEnter autocmds

## Debugging Tips

### Enable verbose logging
Add debug prints in state dispatch:
```lua
function M.dispatch(action_name, ...)
  print("Dispatching:", action_name, vim.inspect({...}))
  -- existing code
end
```

### Inspect state
```lua
:lua print(vim.inspect(require("vscpanel.state").terminals()))
```

### Test manually
```bash
nvim-dev  # From Nix shell
# Or
nvim -u tests/minimal_init.lua --cmd "set rtp+=$(pwd)"
```

### Check window IDs
```lua
:lua print(require("vscpanel.state").window_id())
:lua print(vim.api.nvim_win_is_valid(require("vscpanel.state").window_id()))
```

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for:
- Pull request process
- Code review guidelines
- Commit message conventions
- Additional development setup

## Resources

- [Neovim Lua guide](https://neovim.io/doc/user/lua-guide.html)
- [plenary.nvim](https://github.com/nvim-lua/plenary.nvim)
- [EmmyLua annotations](https://emmylua.github.io/annotation.html)
