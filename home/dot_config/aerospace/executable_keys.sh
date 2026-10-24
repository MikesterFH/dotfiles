#!/bin/bash
# Lists every AeroSpace binding, one section per mode, read from the
# running AeroSpace so the list always matches the loaded config. Used by
# the `aerokeys` alias and the Raycast shortcuts cheat sheet
# (~/.config/cheatsheet/raycast/shortcuts.sh).
export PATH="/opt/homebrew/bin:/usr/local/bin:$PATH"

if ! aerospace config --get mode --json >/dev/null 2>&1; then
  echo "== AeroSpace (not running)"
  exit 0
fi

# Symbols and padding in jq: it counts characters, while awk/printf would
# count the bytes of ⌃⌥⇧ and misalign the columns.
aerospace config --get mode --json |
  jq -r 'def sym: gsub("ctrl-"; "⌃") | gsub("alt-"; "⌥") | gsub("shift-"; "⇧");
    to_entries[]
    | "== AeroSpace: \(.key) mode",
      (.value.binding | to_entries[]
        | (.key | sym) as $k
        | "  \($k)\(" " * ([20 - ($k | length), 1] | max))\(.value | if type == "array" then join("; ") else . end)")'
