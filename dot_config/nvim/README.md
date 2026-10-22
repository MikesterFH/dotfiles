# 💤 LazyVim

A starter template for [LazyVim](https://github.com/LazyVim/LazyVim).
Refer to the [documentation](https://lazyvim.github.io/installation) to get started.

## Windows and psmux

`aserowy/tmux.nvim` is disabled on native Windows: its synchronous tmux
buffer synchronization delays startup, pasting, and command-line entry.
Neovim uses the native clipboard instead. The separate
`nvim-tmux-navigation` plugin remains enabled for `Ctrl+h/j/k/l` navigation
with psmux. `Alt+h/j/k/l` resizes psmux panes directly and asynchronously.
macOS and Linux (including WSL) keep the existing tmux integration.
