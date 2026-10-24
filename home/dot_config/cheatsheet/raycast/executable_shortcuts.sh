#!/bin/bash

# Raycast Script Command: the shortcuts defined in these dotfiles, in
# Raycast's floating window. Add ~/.config/cheatsheet/raycast as a Script
# Commands directory in Raycast once and give "Shortcuts" a hotkey there.
# An optional filter argument keeps only matching lines, under their
# section headings. AeroSpace's part is read live from the running
# AeroSpace; Neovim, tmux and WezTerm come from the .txt files next to
# this folder, which are kept by hand.
#
# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title Shortcuts
# @raycast.mode fullOutput
#
# Optional parameters:
# @raycast.icon ⌨️
# @raycast.packageName Dotfiles
# @raycast.description Cheat sheet for AeroSpace, Neovim, tmux and WezTerm
# @raycast.argument1 { "type": "text", "placeholder": "filter", "optional": true }

dir="$HOME/.config/cheatsheet"

{
  "$HOME/.config/aerospace/keys.sh"
  for f in neovim tmux wezterm; do
    echo
    cat "$dir/$f.txt"
  done
} | awk -v q="${1:-}" '
  q == "" { print; next }
  /^==/ { header = $0; shown = 0; next }
  tolower($0) ~ tolower(q) {
    if (!shown) { print (n++ ? "\n" : "") header; shown = 1 }
    print
  }
'
