#!/usr/bin/env bash
# Asserts the chezmoi Target State rendered by CI for the macOS/Linux Target
# matches expectations, for a given machine Profile (personal/dev/dev-server,
# see docs/adr/0004-machine-profiles.md).
# Usage: assert-unix.sh <dest-dir> <profile>
#
# Shared between the macOS and Linux CI jobs — self-detects which of the two
# via `uname -s`, since VS Code's and iTerm2's paths differ between them.
#
# Doesn't use `set -e`: every assertion runs and every failure is reported,
# instead of stopping at the first one.
set -uo pipefail

dest="$1"
profile="$2"

os="$(uname -s)" # Darwin or Linux
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

echo "--- profile=$profile os=$os ---"

# Shells + tmux — core tooling, unconditional across every profile
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

# Git identity: which config.local.* files exist depends on profile —
# personal -> personal+work, dev -> work+client, dev-server -> personal+work.
case "$profile" in
personal | dev-server)
    assert_file ".config/git/config.local.personal"
    assert_file ".config/git/config.local.work"
    assert_absent ".config/git/config.local.client"
    ;;
dev)
    assert_absent ".config/git/config.local.personal"
    assert_file ".config/git/config.local.work"
    assert_file ".config/git/config.local.client"
    ;;
*)
    bad "unknown profile: $profile"
    ;;
esac

# GUI-app configs: dev-server's Application list is empty, so it gets none;
# personal/dev's Application list carries every app (see .chezmoi.toml.tmpl).
if [ "$profile" = "dev-server" ]; then
    assert_absent ".config/wezterm"
    assert_absent ".config/zed"
    if [ "$os" = "Darwin" ]; then
        assert_absent "Library/Application Support/Code"
        assert_absent "Library/Application Support/iTerm2"
    else
        assert_absent ".config/Code"
    fi
else
    assert_file ".config/wezterm/wezterm.lua"
    assert_file ".config/zed/keymap.jsonc"
    assert_file ".config/zed/settings.jsonc"
    if [ "$os" = "Darwin" ]; then
        assert_file "Library/Application Support/Code/User/settings.json"
        assert_file "Library/Application Support/iTerm2/DynamicProfiles/Nvim_Tmux_Term.json"
    else
        assert_file ".config/Code/User/settings.json"
    fi
fi

# macOS Application manifest (Homebrew), see
# docs/adr/0006-application-category-and-profile-manifests.md: macOS-only,
# one `cask` line per app in the Profile's Application list that has a
# macOS identifier (windows-terminal doesn't, so it's never expected here).
if [ "$os" = "Darwin" ]; then
    brewfile="$dest/.config/homebrew/Brewfile"
    assert_file ".config/homebrew/Brewfile"
    if [ "$profile" = "dev-server" ]; then
        if [ -f "$brewfile" ] && grep -q '^cask ' "$brewfile"; then
            bad "Brewfile should have no cask entries for dev-server, has some"
        else
            ok "Brewfile has no cask entries for dev-server"
        fi
    else
        for cask in wezterm visual-studio-code zed iterm2; do
            if [ -f "$brewfile" ] && grep -qE "^cask \"$cask\"\$" "$brewfile"; then
                ok "Brewfile: cask \"$cask\" present"
            else
                bad "Brewfile: cask \"$cask\" missing"
            fi
        done
        if [ -f "$brewfile" ] && grep -q 'windows-terminal' "$brewfile"; then
            bad "Brewfile: windows-terminal should never appear (no macOS identifier)"
        fi
    fi
else
    assert_absent ".config/homebrew"
fi

# Linux (Debian/apt) Application manifest, see
# docs/adr/0006-application-category-and-profile-manifests.md: Debian/apt
# only — CI's Linux runner is Ubuntu (Debian family), so this always renders
# there. One package name per line, one per app in the Profile's
# Application list that has an apt identifier (iterm2/windows-terminal
# don't, so never expected here).
if [ "$os" = "Linux" ]; then
    aptfile="$dest/.config/apt-packages.txt"
    assert_file ".config/apt-packages.txt"
    if [ "$profile" = "dev-server" ]; then
        if [ -f "$aptfile" ] && grep -qE '\S' "$aptfile"; then
            bad "apt-packages.txt should have no packages for dev-server, has some"
        else
            ok "apt-packages.txt has no packages for dev-server"
        fi
    else
        for pkg in wezterm code zed; do
            if [ -f "$aptfile" ] && grep -qxF "$pkg" "$aptfile"; then
                ok "apt-packages.txt: $pkg present"
            else
                bad "apt-packages.txt: $pkg missing"
            fi
        done
        if [ -f "$aptfile" ] && grep -qE 'iterm2|windows-terminal' "$aptfile"; then
            bad "apt-packages.txt: iterm2/windows-terminal should never appear (no Linux identifier)"
        fi
    fi
else
    assert_absent ".config/apt-packages.txt"
fi

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
    echo "One or more assertions failed (profile=$profile)." >&2
    exit 1
fi

echo "All macOS/Linux Target assertions passed (profile=$profile)."
