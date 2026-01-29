#!/usr/bin/env zsh
# .zshrc - Interactive shell setup
# Loaded for every new terminal. For prompt, aliases, keybindings, history.

# -- oh-my-zsh ----------------------------------------------------------------

plugins=(git)
export ZSH="$HOME/.oh-my-zsh"
[ -d "$ZSH" ] && source "$ZSH"/oh-my-zsh.sh

# -- history ------------------------------------------------------------------

HISTFILE=$HOME/.zhistory
export SAVEHIST=1000
export HISTSIZE=999
setopt share_history
setopt hist_expire_dups_first
setopt hist_ignore_dups
setopt hist_verify

# -- keybindings --------------------------------------------------------------

bindkey '^[[A' history-search-backward
bindkey '^[[B' history-search-forward

# -- aliases ------------------------------------------------------------------

[ -f ~/.zsh_aliases ] && . ~/.zsh_aliases

# -- tool integrations (interactive) -----------------------------------------

command -v zoxide &>/dev/null && eval "$(zoxide init zsh)"
command -v starship &>/dev/null && eval "$(starship init zsh)"
command -v mise &>/dev/null && eval "$(mise activate zsh)"
