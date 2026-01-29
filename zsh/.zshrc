#!/usr/bin/env zsh
# If you come from bash you might have to change your $PATH.
# export PATH=$HOME/bin:/usr/local/bin:$PATH

# Define plugins for oh-my-zsh (used by oh-my-zsh.sh)
plugins=(
  git)

# Path to your oh-my-zsh installation.
export ZSH="$HOME/.oh-my-zsh"

export PATH="/opt/homebrew/sbin:$PATH"
export PATH="$HOME/.local/bin:$PATH"

source "$ZSH"/oh-my-zsh.sh

# You may need to manually set your language environment
export LANG=de_CH.UTF-8

# active vi mode for terminal
# set -o vi

# history setup - these variables are used by zsh internally
HISTFILE=$HOME/.zhistory
export SAVEHIST=1000
export HISTSIZE=999
setopt share_history
setopt hist_expire_dups_first
setopt hist_ignore_dups
setopt hist_verify

# completion using arrow keys (based on history)
bindkey '^[[A' history-search-backward
bindkey '^[[B' history-search-forward

if [ -f ~/.zsh_aliases ]; then
  . ~/.zsh_aliases
fi

# ---- Zoxide (better cd) ----
eval "$(zoxide init zsh)"

# starship setup
eval "$(starship init zsh)"

# cargo
. "$HOME/.cargo/env"
# esp toolchain for rust
. "$HOME/export-esp.sh"

# nvm (Node Version Manager)
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"                   # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion" # This loads nvm bash_completion

source /opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh

# Added by Windsurf
export PATH="$HOME/.codeium/windsurf/bin:$PATH"

# pnpm
export PNPM_HOME="$HOME/Library/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac
# pnpm end

# bun completions
[ -s "$HOME/.bun/_bun" ] && source "$HOME/.bun/_bun"

# bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"
export PATH="/opt/homebrew/opt/libpq/bin:$PATH"
