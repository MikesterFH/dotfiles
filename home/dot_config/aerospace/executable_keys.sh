#!/bin/bash
# Lists every AeroSpace binding, grouped by mode, read from the running
# AeroSpace so the list always matches the loaded config. Prints to the
# terminal (`aerokeys` alias), or with --show opens it in a Quick Look
# window (the ctrl-alt-c binding in aerospace.toml).
export PATH="/opt/homebrew/bin:/usr/local/bin:$PATH"

list() {
  aerospace config --get mode --json |
    jq -r 'to_entries[]
      | "\n[\(.key)]",
        (.value.binding | to_entries[]
          | "  \(.key)\t\(.value | if type == "array" then join("; ") else . end)")' |
    sed -e 's/ctrl-/⌃/' -e 's/alt-/⌥/' -e 's/shift-/⇧/' |
    column -t -s $'\t'
}

if [ "${1:-}" = "--show" ]; then
  out="${TMPDIR:-/tmp}/aerospace-keys.txt"
  list >"$out"
  qlmanage -p "$out" >/dev/null 2>&1
else
  list
fi
