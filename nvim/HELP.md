# 🚀 Neovim Configuration

A modern, feature-rich Neovim configuration built on [LazyVim](https://github.com/LazyVim/LazyVim) - designed for productive development with powerful IDE features, intuitive keybindings, and extensive customization.

## 📑 Table of Contents

- [🎯 Overview](#-overview)
- [✨ Features](#-features)
- [🔧 Installation](#-installation)
- [⌨️ Key Bindings](#️-key-bindings)
- [📦 Plugins](#-plugins)
- [🎨 Customization](#-customization)
- [🔍 Usage Guide](#-usage-guide)
- [🛠️ Troubleshooting](#️-troubleshooting)
- [📚 Additional Resources](#-additional-resources)

## 🎯 Overview

This Neovim configuration transforms your editor into a powerful development environment with:

- **Modern IDE features**: LSP, auto-completion, syntax highlighting, and more
- **LazyVim foundation**: Built on the excellent LazyVim distribution for stability and performance
- **Developer-focused**: Optimized for common programming workflows and languages
- **Highly customizable**: Easy to extend and modify to fit your needs
- **Fast startup**: Lazy-loading plugins ensure quick boot times

### What is LazyVim?

LazyVim is a Neovim setup powered by [lazy.nvim](https://github.com/folke/lazy.nvim) to make it easy to customize and extend your config. This configuration extends LazyVim with additional customizations and plugins tailored for development workflows.

## ✨ Features

### 🧠 Intelligence & Completion
- **LSP (Language Server Protocol)** support for 20+ languages
- **Auto-completion** with context-aware suggestions
- **Code diagnostics** with inline error/warning display
- **Go-to definition** and find references
- **Code actions** and refactoring support
- **Hover documentation** and signature help

### 🎨 Visual & Interface
- **Syntax highlighting** with Tree-sitter
- **Modern UI** with clean, distraction-free design
- **Git integration** with visual indicators and diff views
- **File explorer** with tree view and quick navigation
- **Statusline** with project information and diagnostics
- **Tabline** for buffer management

### 🔍 Search & Navigation
- **Fuzzy finder** for files, buffers, and text search
- **Telescope integration** for powerful search capabilities
- **Quick file switching** and project navigation
- **Symbol search** across the project
- **Live grep** with regex support

### 🛠️ Development Tools
- **Terminal integration** with toggleable terminal windows
- **Git integration** with Fugitive and Gitsigns
- **Debugging support** with DAP (Debug Adapter Protocol)
- **Testing integration** for various frameworks
- **Code formatting** with automatic formatter detection
- **Snippet support** for faster code generation

### ⚡ Performance
- **Lazy loading** - plugins load only when needed
- **Fast startup** - typically under 100ms
- **Efficient memory usage** with smart plugin management
- **Async operations** for non-blocking file operations

## 🔧 Installation

This Neovim configuration is automatically installed when you run the main dotfiles installation. For manual installation:

### Prerequisites
- **Neovim 0.8+** (0.9+ recommended)
- **Git** for plugin management
- **Node.js** (for certain LSP servers)
- **Python 3** with `pynvim` package
- **Ripgrep** for telescope searching
- **A terminal with true color support**

### Manual Setup
```bash
# Backup existing Neovim configuration
mv ~/.config/nvim ~/.config/nvim.backup

# Clone this configuration
git clone <dotfiles-repo> ~/.dotfiles
cd ~/.dotfiles

# Stow the Neovim configuration
stow nvim

# Start Neovim (plugins will auto-install)
nvim
```

## ⌨️ Key Bindings

### 🗂️ General Navigation

| Key | Action | Mode | Description |
|-----|--------|------|-------------|
| `<Space>` | Leader key | Normal | Main prefix for most commands |
| `<C-h/j/k/l>` | Navigate windows | Normal | Move between splits |
| `<S-h/l>` | Navigate buffers | Normal | Switch between open buffers |
| `<C-u/d>` | Scroll half page | Normal | Quick page navigation |

### 📁 File Management

| Key | Action | Mode | Description |
|-----|--------|------|-------------|
| `<leader>e` | Toggle file explorer | Normal | Open/close Neo-tree |
| `<leader>E` | Focus file explorer | Normal | Jump to file explorer |
| `<leader>ff` | Find files | Normal | Fuzzy find files in project |
| `<leader>fr` | Recent files | Normal | Find recently opened files |
| `<leader>fw` | Find word | Normal | Search for word under cursor |

### 🔍 Search & Replace

| Key | Action | Mode | Description |
|-----|--------|------|-------------|
| `<leader>/` | Search in file | Normal | Local file search |
| `<leader>sg` | Live grep | Normal | Search text in all files |
| `<leader>sw` | Search word | Normal | Search current word in project |
| `<leader>sr` | Search & replace | Normal | Find and replace in project |
| `<C-n>` | Next match | Normal | Jump to next search result |

### 💾 Code Navigation & Editing

| Key | Action | Mode | Description |
|-----|--------|------|-------------|
| `gd` | Go to definition | Normal | Jump to symbol definition |
| `gr` | Go to references | Normal | Find all references |
| `gi` | Go to implementation | Normal | Jump to implementation |
| `K` | Hover documentation | Normal | Show documentation popup |
| `<leader>ca` | Code actions | Normal | Show available code actions |
| `<leader>cr` | Rename symbol | Normal | Rename symbol across project |

### 🐛 Diagnostics & Debugging

| Key | Action | Mode | Description |
|-----|--------|------|-------------|
| `]d` | Next diagnostic | Normal | Jump to next error/warning |
| `[d` | Previous diagnostic | Normal | Jump to previous error/warning |
| `<leader>cd` | Show diagnostics | Normal | Open diagnostics window |
| `<leader>cl` | Code lens | Normal | Show/run code lens |

### 📄 Buffer & Window Management

| Key | Action | Mode | Description |
|-----|--------|------|-------------|
| `<leader>bb` | Browse buffers | Normal | List all open buffers |
| `<leader>bd` | Delete buffer | Normal | Close current buffer |
| `<leader>bD` | Delete buffer (force) | Normal | Force close buffer |
| `<C-w>s` | Split horizontal | Normal | Create horizontal split |
| `<C-w>v` | Split vertical | Normal | Create vertical split |
| `<C-w>q` | Close window | Normal | Close current window |

### 🔧 Terminal & Tasks

| Key | Action | Mode | Description |
|-----|--------|------|-------------|
| `<C-\>` | Toggle terminal | Normal/Terminal | Open/close terminal |
| `<leader>gg` | Open lazygit | Normal | Git interface |
| `<leader>tt` | Run tests | Normal | Execute project tests |
| `<leader>tr` | Run test file | Normal | Run tests in current file |

### 🎨 UI & Visual

| Key | Action | Mode | Description |
|-----|--------|------|-------------|
| `<leader>uh` | Toggle inlay hints | Normal | Show/hide type hints |
| `<leader>ul` | Toggle line numbers | Normal | Show/hide line numbers |
| `<leader>uw` | Toggle word wrap | Normal | Enable/disable word wrap |
| `<leader>uz` | Toggle zen mode | Normal | Distraction-free editing |

## 📦 Plugins

### Core Plugins

| Plugin | Purpose | Configuration |
|--------|---------|---------------|
| **LazyVim** | Base configuration framework | Pre-configured with sensible defaults |
| **lazy.nvim** | Plugin manager | Lazy loading, automatic updates |
| **nvim-lspconfig** | LSP configuration | Language server setup |
| **nvim-cmp** | Completion engine | Auto-completion with multiple sources |
| **Telescope** | Fuzzy finder | File/text search, project navigation |
| **Neo-tree** | File explorer | Project tree view and file management |

### Language Support

| Language | LSP Server | Additional Features |
|----------|------------|-------------------|
| **JavaScript/TypeScript** | tsserver | Formatting, linting, debugging |
| **Python** | pyright | Type checking, auto-imports |
| **Rust** | rust-analyzer | Cargo integration, testing |
| **Go** | gopls | Formatting, testing, debugging |
| **Lua** | lua-ls | Neovim API completion |
| **JSON/YAML** | json-ls, yaml-ls | Schema validation |

### Development Tools

| Plugin | Purpose | Features |
|--------|---------|----------|
| **Gitsigns** | Git integration | Diff indicators, blame, hunks |
| **Fugitive** | Git commands | Full Git workflow in Neovim |
| **nvim-dap** | Debugging | Debug adapter protocol support |
| **Trouble** | Diagnostics | Better error/warning display |
| **Todo-comments** | TODO tracking | Highlight and search TODO items |

## 🎨 Customization

### Adding Custom Keybindings

Create or edit `~/.config/nvim/lua/config/keymaps.lua`:

```lua
-- Custom keybinding example
vim.keymap.set("n", "<leader>xx", function()
  -- Your custom function here
  print("Custom command executed!")
end, { desc = "Custom Command" })

-- Override existing keybinding
vim.keymap.set("n", "<leader>e", "<cmd>Neotree toggle<cr>", { desc = "Toggle Explorer" })
```

### Installing Additional Plugins

Add new plugins in `~/.config/nvim/lua/plugins/`:

```lua
-- lua/plugins/my-plugin.lua
return {
  {
    "username/plugin-name",
    config = function()
      require("plugin-name").setup({
        -- Plugin configuration
      })
    end,
  }
}
```

### Language-Specific Configuration

Customize language servers in `~/.config/nvim/lua/config/languages/`:

```lua
-- lua/config/languages/python.lua
return {
  lsp = {
    servers = {
      pyright = {
        settings = {
          python = {
            analysis = {
              typeCheckingMode = "strict",
            },
          },
        },
      },
    },
  },
}
```

### Color Scheme & Appearance

Change theme in `~/.config/nvim/lua/config/options.lua`:

```lua
-- Set colorscheme
vim.cmd.colorscheme("tokyonight-night") -- or "catppuccin", "gruvbox", etc.

-- Customize appearance
vim.opt.background = "dark"
vim.opt.termguicolors = true
```

## 🔍 Usage Guide

### Getting Started

1. **First Launch**: Open Neovim and let plugins install automatically
2. **Open a Project**: Use `nvim /path/to/project` or `:cd /path/to/project`
3. **File Navigation**: Press `<leader>ff` to search files
4. **Code Exploration**: Use `gd` to jump to definitions

### Common Workflows

#### Opening and Navigating Projects
```bash
# Open project directory
nvim /path/to/project

# Or open specific file
nvim /path/to/project/file.js
```

Inside Neovim:
- `<leader>e` - Toggle file explorer
- `<leader>ff` - Find files
- `<leader>sg` - Search text in project

#### Code Development
1. **Navigate to file**: `<leader>ff` → type filename
2. **Jump to definition**: `gd` on symbol
3. **Get documentation**: `K` on symbol
4. **Find references**: `gr` on symbol
5. **Rename symbol**: `<leader>cr` on symbol

#### Git Workflow
1. **View changes**: `:Gitsigns preview_hunk`
2. **Stage hunks**: `:Gitsigns stage_hunk`
3. **Open lazygit**: `<leader>gg`
4. **View blame**: `:Gitsigns blame_line`

### Tips for Productivity

1. **Use the command palette**: `<leader><space>` for quick actions
2. **Master telescope**: `<leader>f*` commands for finding anything
3. **Learn text objects**: `ciw`, `ca"`, `di(` for efficient editing
4. **Use macros**: `qa` to record, `@a` to replay
5. **Leverage LSP**: Let the language server guide your navigation

## 🛠️ Troubleshooting

### Common Issues

#### LSP Not Working
```bash
# Check LSP status
:LspInfo

# Install language server manually
:Mason
```

#### Plugins Not Loading
```bash
# Reinstall plugins
:Lazy clean
:Lazy install

# Check plugin status
:Lazy
```

#### Performance Issues
```bash
# Profile startup time
nvim --startuptime startup.log

# Check loaded plugins
:Lazy profile
```

### Configuration Conflicts

If you experience issues after customization:

1. **Check syntax**: `:messages` for error messages
2. **Reset configuration**: Remove `~/.local/share/nvim` and restart
3. **Test minimal config**: Use `:Lazy health` to check plugin health

### Getting Help

- **Built-in help**: `:help <topic>` (e.g., `:help telescope`)
- **LazyVim docs**: https://lazyvim.github.io/
- **Keybinding help**: `<leader>?` or `:WhichKey`

## 📚 Additional Resources

### Documentation
- [LazyVim Documentation](https://lazyvim.github.io/)
- [Neovim User Manual](https://neovim.io/doc/user/)
- [Lua Guide for Neovim](https://github.com/nanotee/nvim-lua-guide)

### Learning Resources
- [Neovim from Scratch](https://www.youtube.com/watch?v=ctH-a-1eUME&list=PLhoH5vyxr6Qq41NFL4GvhFp-WLd5xzIzZ)
- [LazyVim for Ambitious Developers](https://www.youtube.com/watch?v=N93cTbtLCIM)
- [Mastering Neovim](https://www.youtube.com/c/ThePrimeagen)

### Plugin Ecosystems
- [Awesome Neovim](https://github.com/rockerBOO/awesome-neovim)
- [LazyVim Extras](https://lazyvim.github.io/extras)
- [Mason Registry](https://mason-registry.dev/)

---

**🎉 Happy coding!** This Neovim configuration is designed to grow with you. Start with the basics and gradually explore advanced features as you become more comfortable.
