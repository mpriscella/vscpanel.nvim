# vscpanel.nvim

[![Tests](https://github.com/mpriscella/vscpanel.nvim/actions/workflows/test.yaml/badge.svg)](https://github.com/mpriscella/vscpanel.nvim/actions/workflows/test.yaml)

A toggleable terminal panel for Neovim with maximize/minimize functionality.

## Features

- **Toggle terminal panel** - Show/hide terminal panel with a simple command
- **Maximize/minimize** - Toggle between panel and full-window modes
- **Dynamic winbar** - Visual controls with contextual icons
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
    require("vscpanel").setup({
      size = 18,
      position = "bottom"
    })
  end,
  keys = {
    {
      '<leader>t',
      mode = { 'n', 't' },
      function()
        require('vscpanel.panel').toggle_panel()
      end,
    },
    {
      '<leader> ',
      mode = { 'n', 't' },
      function()
        require('vscpanel').max_toggle()
      end,
    },
    {
      '<leader>s',
      mode = { 'n', 't' },
      function()
        require('vscpanel.views.terminal.shell-picker').open()
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
Plug 'mpriscella/vscpanel.nvim'
lua require("vscpanel").setup()
```

## Configuration

### Default Settings

```lua
require("vscpanel").setup({
  size = 18,                    -- Panel height/width
  shell = vim.o.shell,          -- Shell to use
  position = "bottom",          -- "bottom", "top", "left", "right"
  winbar = {
    enabled = true,             -- Show winbar
  },
})
```

### Configuration Options

| Option           | Type      | Default       | Description                                                    |
| ---------------- | --------- | ------------- | -------------------------------------------------------------- |
| `size`           | `number`  | `18`          | Height (for bottom/top) or width (for left/right) of the panel |
| `shell`          | `string`  | `vim.o.shell` | Shell command to use for terminals                             |
| `position`       | `string`  | `"bottom"`    | Panel position: `"bottom"`, `"top"`, `"left"`, `"right"`       |
| `winbar.enabled` | `boolean` | `true`        | Show the winbar with controls                                  |

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

### API Functions

```lua
-- Toggle panel
require("vscpanel.panel").toggle_panel()

-- Maximize/minimize
require("vscpanel").max_toggle()

-- Show help
require("vscpanel").show_help()

-- Update winbar
require("vscpanel").update_winbar()
```

## Examples

### Basic Setup

```lua
require("vscpanel").setup()
```

### Right-side Panel

```lua
require("vscpanel").setup({
  size = 80,
  position = "right",
})
```

### Top Panel

```lua
require("vscpanel").setup({
  size = 15,
  position = "top",
})
```

### Custom Shell and Behavior

```lua
require("vscpanel").setup({
  size = 25,
  shell = "/bin/zsh",
})
```

### Disable Winbar

```lua
require("vscpanel").setup({
  winbar = {
    enabled = false
  }
})
```

## Development

### Testing

Run tests with:

```bash
just test
```

### Health Check

Check plugin health:

```vim
:checkhealth vscpanel
```

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests for new functionality
5. Run the test suite
6. Submit a pull request

## License

MIT License - see [LICENSE](LICENSE) for details.

## Acknowledgments

- Built with [plenary.nvim](https://github.com/nvim-lua/plenary.nvim) for testing
- Inspired by various terminal plugins in the Neovim ecosystem
