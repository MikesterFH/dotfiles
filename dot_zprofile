#!/usr/bin/env zsh
# .zprofile - Login shell setup
# Loaded once at login. For PATH, environment variables, and tool initialization.

# -- PATH ---------------------------------------------------------------------

eval "$(/opt/homebrew/bin/brew shellenv)"
export PATH="$HOME/.local/bin:$PATH"
[ -d /opt/homebrew/opt/libpq/bin ] && export PATH="/opt/homebrew/opt/libpq/bin:$PATH"

# -- Environment --------------------------------------------------------------

export LANG=de_CH.UTF-8

# -- Homebrew plugins ---------------------------------------------------------

[ -f /opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh ] \
  && source /opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh

# -- cargo / rust -------------------------------------------------------------

[ -f "$HOME/.cargo/env" ] && . "$HOME/.cargo/env"
[ -f "$HOME/export-esp.sh" ] && . "$HOME/export-esp.sh"

# -- nvm (Node Version Manager) ----------------------------------------------

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"

# -- bun ----------------------------------------------------------------------

export BUN_INSTALL="$HOME/.bun"
[ -s "$BUN_INSTALL/bin/bun" ] && export PATH="$BUN_INSTALL/bin:$PATH"
[ -s "$HOME/.bun/_bun" ] && source "$HOME/.bun/_bun"

# -- mise ---------------------------------------------------------------------

command -v mise &>/dev/null && eval "$(mise activate zsh --shims)"
