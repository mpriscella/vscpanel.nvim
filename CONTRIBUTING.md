# Contributing to vscpanel.nvim

Thank you for your interest in contributing to vscpanel.nvim! This document
provides guidelines and information for contributors.

## Development Setup

### Prerequisites

- Neovim 0.8.0 or higher
- [just](https://github.com/casey/just) command runner
- [Nix](https://nixos.org/) (optional, for reproducible development environment)

### Getting Started

1. Fork and clone the repository:

   ```bash
   git clone https://github.com/yourusername/vscpanel.nvim.git
   cd vscpanel.nvim
   ```

2. Set up the development environment:

   ```bash
   # Using Nix (recommended)
   nix develop

   # Or install dependencies manually:
   # - luacheck (for linting)
   # - stylua (for formatting)
   # - plenary.nvim (for testing)
   ```

## Development Workflow

### Running Tests

```bash
# Run all tests and checks
just check

# Run only unit tests
just run-unit-tests

# Run linting
just lint

# Check documentation
just docs

# Run health check
just health
```

### Code Formatting

Format your code before committing:

```bash
# Format Nix files
nix fmt

# Format Lua files
stylua .
```

### Manual Testing

For manual testing during development:

```bash
# Minimal Neovim runtime for testing
nvim-dev  # (available in Nix shell)

# Alternative approach
nvim -u tests/minimal_init.lua --cmd "set rtp+=$(pwd)"
```

## Code Style Guidelines

### Lua Code Style

- **Language**: Lua 5.1+ (Neovim compatibility)
- **Formatting**: 2-space indentation, single quotes for strings
- **Line length**: Maximum 120 characters
- **Imports**: Use `require('vscpanel.<module>')`, cache in locals
- **Naming**:
  - Modules and tables: `lower_snake_case`
  - Exported module table: `M`
  - Constants: `UPPER_SNAKE_CASE`
  - User options: `lower_snake_case`

### Documentation

- Add EmmyLua annotations (`--- @param`, `--- @return`) for public APIs
- Include succinct docstrings for public functions
- Keep documentation up to date with code changes

### Error Handling

- Validate inputs and fail fast with `error()` for programmer errors
- Use `pcall()` for Neovim API calls that can fail
- Report user-facing issues via `vim.notify()` with appropriate log levels

### Neovim API Best Practices

- Guard window/buffer validity with `vim.api.nvim_*_is_valid()`
- Avoid hard failures in autocommands and keymaps
- Use `vim.schedule()` or `vim.defer_fn()` when needed to avoid focus/layout issues

### State Management

- Keep minimal state in module (`M.state`)
- Use tab-scoped state (`vim.t`) when appropriate
- Never store window IDs without validity checks
- Avoid O(n²) operations in hot paths

## Testing

### Running Tests

The project uses plenary.nvim for testing:

```bash
# Run all tests
just run-unit-tests

# Run specific test file
nvim --headless -u tests/minimal_init.lua -c "lua require('plenary.busted').run('tests/specific_test_spec.lua')" -c "qa!"
```

### Test Coverage

Tests cover:

- Panel creation and management
- State management and persistence
- Terminal creation, switching, and deletion
- Configuration validation
- Keybinding setup
- UI components (winbar, tabs)
- Error handling and edge cases

### Writing Tests

- Place test files in `tests/` with `*_spec.lua` naming
- Use descriptive test names and organize with `describe()` and `it()`
- Clean up state in `before_each()` hooks
- Test both success and failure cases

## Architecture Overview

### Core Modules

- **init.lua**: Main plugin setup and public API
- **panel.lua**: Window management for the panel
- **state.lua**: Centralized state management with action dispatch pattern
- **config.lua**: Configuration handling and validation

### Supporting Modules

- **terminal.lua**: Terminal creation and lifecycle management
- **winbar.lua**: Dynamic UI controls in the panel
- **tabs.lua**: Multi-terminal tab interface
- **commands.lua**: Ex-command definitions
- **keybinds.lua**: Buffer-local keybinding setup
- **help.lua**: Integrated help system

### Design Patterns

- **State Management**: Centralized state with action dispatching
- **Module Pattern**: Each file exports a table with public functions
- **Configuration**: Normalized and validated user options
- **Event Handling**: Autocommands for terminal lifecycle events

## Submitting Changes

### Pull Request Process

1. Create a feature branch from `main`
2. Make your changes following the code style guidelines
3. Add or update tests as needed
4. Run the full test suite: `just check`
5. Update documentation if needed
6. Submit a pull request with a clear description

### Commit Messages

Use clear, descriptive commit messages:

```
feat: add terminal renaming functionality
fix: handle edge case in terminal deletion
docs: update configuration examples
test: add coverage for panel positioning
```

### Code Review

- All changes require code review
- Address feedback promptly and professionally
- Ensure CI passes before requesting review

## Getting Help

- Check existing [issues](https://github.com/mpriscella/vscpanel.nvim/issues) for known problems
- Use [discussions](https://github.com/mpriscella/vscpanel.nvim/discussions) for questions
- Review the codebase and existing tests for patterns and examples

## License

By contributing to vscpanel.nvim, you agree that your contributions will be licensed under the same license as the project.
