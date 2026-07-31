#!/usr/bin/env bash
# Asserts the chezmoi Target State rendered by CI for the macOS/Linux Target
# matches expectations. Usage: assert-unix.sh <dest-dir>
#
# Doesn't use `set -e`: every assertion runs and every failure is reported,
# instead of stopping at the first one.
set -uo pipefail

dest="$1"
fail=0

ok() { printf '[OK]   %s\n' "$*"; }
bad() {
    printf '[FAIL] %s\n' "$*"
    fail=1
}

assert_file() {
    if [ -f "$dest/$1" ]; then
        ok "present: $1"
    else
        bad "expected file missing: $1"
    fi
}

assert_absent() {
    if [ -e "$dest/$1" ]; then
        bad "unexpected path present: $1"
    else
        ok "absent: $1"
    fi
}

# Shells + tmux
assert_file ".bashrc"
assert_file ".bash_aliases"
assert_file ".zshrc"
assert_file ".zprofile"
assert_file ".zsh_aliases"
assert_file ".config/tmux/tmux.conf"

# Windows-only paths must not appear on macOS/Linux
assert_absent "Documents/PowerShell/Microsoft.PowerShell_profile.ps1"
assert_absent "AppData"
assert_absent "AppData/Local/Packages/Microsoft.WindowsTerminal_8wekyb3d8bbwe/LocalState/settings.json"

# zed, on every Target
assert_file ".config/zed/keymap.jsonc"
assert_file ".config/zed/settings.jsonc"

# Rendered git config: autocrlf must be "input", never "true"
gitconfig="$dest/.config/git/config"
if [ -f "$gitconfig" ]; then
    if grep -qE '^\s*autocrlf\s*=\s*input\s*$' "$gitconfig"; then
        ok "git config: autocrlf = input"
    else
        bad "git config: autocrlf = input not found in $gitconfig"
    fi
    if grep -qE '^\s*autocrlf\s*=\s*true\s*$' "$gitconfig"; then
        bad "git config: autocrlf = true present (should be input on this Target)"
    fi
else
    bad "expected file missing: .config/git/config"
fi

# SKIP_FILES/SKIP_DIRS (from .chezmoiignore) must not have leaked through.
# Kept in sync by hand with the catch-all list at the bottom of
# .chezmoiignore (and its assert-windows.ps1 counterpart) — update all three
# together.
skip_hits=$(find "$dest" \
    \( -name 'README.md' -o -name 'readme.md' -o -name 'README' \
    -o -name 'LICENSE' -o -name 'CHANGELOG.md' -o -name 'HELP.md' \
    -o -name 'which-key.yaml' -o -name 'Thumbs.db' \
    -o -name 'node_modules' -o -name '__pycache__' -o -name 'venv' \) \
    2>/dev/null)
if [ -z "$skip_hits" ]; then
    ok "no SKIP_FILES/SKIP_DIRS matches under $dest"
else
    bad "SKIP_FILES/SKIP_DIRS matches found:"
    printf '%s\n' "$skip_hits" >&2
    fail=1
fi

if [ "$fail" -ne 0 ]; then
    echo "One or more assertions failed." >&2
    exit 1
fi

echo "All macOS/Linux Target assertions passed."
