# vscpanel.nvim

[![Tests](https://github.com/mpriscella/vscpanel.nvim/actions/workflows/test.yaml/badge.svg)](https://github.com/mpriscella/vscpanel.nvim/actions/workflows/test.yaml)

A VSCode style panel for Neovim.

## Features

- **Toggleable panel** - Show/hide panel with a simple command
- **Maximize/minimize panel** - Toggle between panel and full-window modes
- **Dynamic winbar** - Visual controls with contextual nerdfont icons
- **Flexible positioning** - Bottom, top, left, or right panel placement
- **Robust state management** - Handles multiple terminals and window states
- **Extensive configuration** - Customize size, position, shell, and behavior

## Requirements

- Neovim 0.8.0 or higher
- Terminal support (built into Neovim)

## Installation

### lazy.nvim

```lua
{
  "mpriscella/vscpanel.nvim",
  config = function()
    require("vscpanel").setup({})
  end,
  keys = {
    {
      "<leader>t",
      mode = { "n", "t" },
      function()
        require("vscpanel.panel").toggle_panel()
      end,
    },
    {
      "<leader> ",
      mode = { "n", "t" },
      function()
        require("vscpanel").max_toggle()
      end,
    },
    {
      "<leader>s",
      mode = { "n", "t" },
      function()
        require("vscpanel.views.terminal.shell-picker").open()
      end,
    },
  },
}
```

### packer.nvim

```lua
use {
  "mpriscella/vscpanel.nvim",
  config = function()
    require("vscpanel").setup()
  end
}
```

### vim-plug

```vim
Plug "mpriscella/vscpanel.nvim"
lua require("vscpanel").setup()
```

## Configuration

### Default Settings

```lua
require("vscpanel").setup({
  size = 18,                    -- Panel height/width
  shell = vim.o.shell,          -- Shell to use
  position = "bottom",          -- "bottom", "top", "left", "right"
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
})
```

### Configuration Options

| Option                          | Type     | Default       | Description                                                                      |
| ------------------------------- | -------- | ------------- | -------------------------------------------------------------------------------- |
| `shell`                         | `string` | `vim.o.shell` | The path to an executable shell.                                                 |
| `size`                          | `number` | `18`          | The size of the panel when the position is "bottom" or "top".                    |
| `position`                      | `string` | `"bottom"`    | The position of the panel. Either "bottom" (default), "top", "left", or "right". |
| `icons.panel.hide_panel`        | `string` | `""`         |                                                                                  |
| `icons.panel.toggle_panel_size` | `string` | `" "`        |                                                                                  |
| `icons.terminal.close_terminal` | `string` | `""`          |                                                                                  |
| `icons.terminal.help`           | `string` | `"󰋖"`         |                                                                                  |
| `icons.terminal.launch_profile` | `string` | `""`         |                                                                                  |
| `icons.terminal.new_terminal`   | `string` | `""`         |                                                                                  |

## Usage

### Commands

- `:TogglePanel` - Toggle terminal panel visibility
- `:TogglePanelSize` - Toggle maximize/minimize state
- `:ShowTerminalMenu` - Show Terminal Menu
- `:PanelTermHelp` - Show help with all keybindings

### Default Keymaps

- `<leader>t` - Toggle terminal panel
- `<leader> ` - Maximize/minimize terminal panel
- `<leader>s` - Show terminal menu (when in terminal)
- `g?` - Show help (when in terminal or terminal tabs)

## Examples

### Basic Setup

```lua
require("vscpanel").setup()
```

## Development

### Testing

Run tests with:

```bash
just test
```
