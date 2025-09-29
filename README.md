# vscpanel.nvim

[![Tests](https://github.com/mpriscella/vscpanel.nvim/actions/workflows/test.yaml/badge.svg)](https://github.com/mpriscella/vscpanel.nvim/actions/workflows/test.yaml)

A VSCode-style panel for Neovim with advanced multi-terminal management.

**Key highlights:**

- VSCode-inspired terminal panel interface
- Multiple terminal support with tab-based switching
- Smart auto-insert mode for seamless terminal interaction

## Features

### Core Panel Management

- **Toggleable panel** - Show/hide panel with simple commands or keybindings
- **Maximize/minimize panel** - Toggle between normal and full-window modes
- **Flexible positioning** - Bottom, top, left, or right panel placement
- **Dynamic winbar** - Visual controls with contextual Nerd Font icons

### Multi-Terminal Support

- **Multiple terminals** - Create and manage multiple terminal instances
- **Terminal tabs** - Visual tab interface for switching between terminals
- **Terminal renaming** - Custom labels for easy terminal identification
- **Smart terminal deletion** - Automatic cleanup and state management
- **Shell picker** - Quick access to create terminals with different shells

### Enhanced User Experience

- **Auto-insert mode** - Automatically enter insert mode when focusing terminals
- **Buffer-local keybindings** - Context-aware keyboard shortcuts
- **Comprehensive help system** - Built-in help with all available keybindings
- **Extensive configuration** - Customize size, position, shell, icons, and behavior

## Requirements

- Neovim 0.8.0 or higher
- Terminal support (built into Neovim)

## Installation

### lazy.nvim

```lua
{
  "mpriscella/vscpanel.nvim",
  config = function()
    require("vscpanel").setup({
      -- Optional: customize your setup
      size = 20,
      position = "bottom",
      shell = vim.o.shell,
    })
  end,
  keys = {
    {
      "<leader>t",
      mode = { "n", "t" },
      function()
        require("vscpanel.panel").toggle_panel()
      end,
      desc = "Toggle Panel",
    },
    {
      "<Ctrl-space>",
      mode = { "n", "t" },
      function()
        require("vscpanel").max_toggle()
      end,
      desc = "Maximize/Minimize Panel",
    },
  },
}
```

## Configuration

<details><summary>Default Settings</summary>

```lua
--- @class vscpanel.Config
--- @field icons vscpanel.Config.Icons?
--- @field shell string? The path to an executable shell.
--- @field size integer? The size of the panel when the position is "bottom" or "top".
--- @field position string? The position of the panel. Either "bottom" (default), "top", "left", or "right".

--- @class vscpanel.Config.Icons
--- @field panel vscpanel.Config.Icons.Panel?
--- @field terminal vscpanel.Config.Icons.Terminal?

--- @class vscpanel.Config.Icons.Panel
--- @field hide_panel string?
--- @field toggle_panel_size string?

--- @class vscpanel.Config.Icons.Terminal
--- @field close_terminal string?
--- @field help string?
--- @field launch_profile string?
--- @field new_terminal string?

--- @type vscpanel.Config
local defaults = {
  size = 18,
  shell = vim.o.shell,
  position = "bottom",
  icons = {
    panel = {
      hide_panel = "",
      toggle_panel_size = " ",
    },
    terminal = {
      close_terminal = "",
      help = "󰋖",
      launch_profile = "",
      new_terminal = "",
    },
  },
}
```

</details>

## Usage

### Commands

- `:TogglePanel` - Toggle terminal panel visibility
- `:TogglePanelSize` - Toggle maximize/minimize state
- `:ShowTerminalMenu` - Show Terminal Menu
- `:PanelTermHelp` - Show help with all keybindings

### Default Keybindings

These keybindings are automatically set up for terminal buffers within the panel:

| Key         | Mode             | Description                     |
| ----------- | ---------------- | --------------------------------|
| `<C-H>`     | Normal, Terminal | Show help menu                  |
| `<C-N>`     | Normal, Terminal | Open shell picker/terminal menu |
| `<C-Space>` | Normal, Terminal | Maximize/minimize panel         |

**Terminal Tabs (when multiple terminals exist):**

- `<Enter>` - Switch to terminal under cursor
- `<LeftMouse>` - Click to switch to terminal
- `d` - Delete/close terminal under cursor
- `r` - Rename terminal under cursor

**Note:** The plugin doesn't set global keybindings by default. Use the
installation examples above to set up your preferred global shortcuts.
