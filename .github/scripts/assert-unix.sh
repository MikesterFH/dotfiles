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

# Expected identifiers come from the Application data file
# (home/.chezmoidata/applications.toml, docs/adr/0023-applications-from-one-data-file.md),
# read through `chezmoi data` and filtered here with jq, independently of the
# templates' own filtering. Fixed spot checks below guard against a wrong
# entry in the data file passing silently.
repo="$(cd "$(dirname "$0")/../.." && pwd)"
empty_cfg="$(mktemp)"
apps_json="$(chezmoi --source "$repo" --config "$empty_cfg" --config-format toml data --format json |
    jq -c --arg p "$profile" '[.application[] | select(.profiles | index($p))]')"
rm -f "$empty_cfg"
if [ -z "$apps_json" ] || [ "$apps_json" = "[]" ]; then
    echo "[FAIL] could not read Applications for profile $profile from applications.toml" >&2
    exit 1
fi
case "$(uname -m)" in
x86_64 | amd64) arch=amd64 ;;
arm64 | aarch64) arch=arm64 ;;
*) arch="$(uname -m)" ;;
esac
case "$os" in
Darwin) chezmoi_os=darwin ;;
*) chezmoi_os=linux ;;
esac
# jq predicate: mise installs this Application on $os/$arch
via_mise_jq='has("mise")
    and ((has("mise_os") | not) or (.mise_os | index($os) != null))
    and ((has("mise_arch") | not) or (.mise_arch[$os] == null) or (.mise_arch[$os] | index($arch) != null))'
# native_ids <field>: that identifier for every Application of this Profile
# that has it and that mise does not install on this OS/arch
native_ids() {
    jq -r --arg f "$1" --arg os "$chezmoi_os" --arg arch "$arch" \
        ".[] | select(has(\$f) and (($via_mise_jq) | not)) | .[\$f]" <<<"$apps_json"
}
# mise_tools <in|out>: mise keys mise installs (in) or skips (out) on this OS/arch
mise_tools() {
    jq -r --arg os "$chezmoi_os" --arg arch "$arch" --arg want "$1" \
        ".[] | select(has(\"mise\") and .kind != \"runtime\") | select(($via_mise_jq) == (\$want == \"in\")) | .mise" <<<"$apps_json"
}

echo "--- profile=$profile os=$os ---"

# Shells + tmux — core tooling, unconditional across every profile
assert_file ".bashrc"
assert_file ".bash_aliases"
assert_file ".zshrc"
assert_file ".zprofile"
assert_file ".zsh_aliases"
assert_file ".config/tmux/tmux.conf"

# German spell files for nvim, pulled in by .chezmoiexternal.toml.tmpl, see
# docs/adr/0010-nvim-spell-files-as-chezmoi-externals.md
assert_file ".local/share/nvim/site/spell/de.utf-8.spl"
assert_file ".local/share/nvim/site/spell/de.utf-8.sug"

# Global mise tools (node, python for nvim's Mason), see
# docs/adr/0011-nvim-toolchain.md
assert_file ".config/mise/config.toml"

# oh-my-zsh, cloned by a chezmoi git-repo external, see
# docs/adr/0015-default-shells.md
assert_file ".oh-my-zsh/oh-my-zsh.sh"
# mise config: every Application mise installs on this OS/arch is present,
# every one it skips here is absent (docs/adr/0012-linux-cli-tools-via-mise.md,
# docs/adr/0023-applications-from-one-data-file.md).
misefile="$dest/.config/mise/config.toml"
while IFS= read -r tool; do
    [ -n "$tool" ] || continue
    if [ -f "$misefile" ] && grep -qF "\"$tool\" = " "$misefile"; then
        ok "mise config: $tool present"
    else
        bad "mise config: $tool missing"
    fi
done < <(mise_tools in)
while IFS= read -r tool; do
    [ -n "$tool" ] || continue
    if [ -f "$misefile" ] && grep -qF "\"$tool\"" "$misefile"; then
        bad "mise config: $tool should not be installed by mise on $chezmoi_os/$arch"
    fi
done < <(mise_tools out)
# Spot checks independent of the data file: the CLI tools come from mise on
# Linux and macOS (docs/adr/0023-applications-from-one-data-file.md).
for tool in aqua:sxyazi/yazi aqua:BurntSushi/ripgrep; do
    if [ -f "$misefile" ] && grep -qF "\"$tool\" = " "$misefile"; then
        ok "mise config (spot check): $tool present"
    else
        bad "mise config (spot check): $tool missing"
    fi
done
# Neovim and the tree-sitter CLI come from mise on every OS, pinned to an
# exact version so the shared lazy-lock.json fits, see
# docs/adr/0013-neovim-pinned-via-mise.md
for tool in neovim/neovim tree-sitter/tree-sitter; do
    if [ -f "$misefile" ] && grep -qE "^\"aqua:$tool\" = \"[0-9]+\.[0-9]+\.[0-9]+\"\$" "$misefile"; then
        ok "mise config: aqua:$tool pinned"
    else
        bad "mise config: aqua:$tool missing or not pinned to an exact version"
    fi
done

# mermaid-cli was removed (ADR 0019 update, issue #34): its npm install
# fails mise's trust policy and with it the whole `mise install`
if [ -f "$misefile" ] && grep -q '^"npm:' "$misefile"; then
    bad "mise config: npm: entry present (mermaid-cli was removed)"
else
    ok "mise config: no npm: entries"
fi

# helix and hunk configs, CLI tools so on every Profile; helix's lives in
# AppData on Windows, hunk's in ~/.config everywhere
assert_file ".config/helix/config.toml"
assert_file ".config/helix/languages.toml"
assert_file ".config/hunk/config.toml"

# Windows-only paths must not appear on macOS/Linux
assert_absent ".psmux.conf"
assert_absent ".config/powershell/profile.ps1"
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

# GUI-app configs: dev-server's Application list holds only CLI tools, so it gets none;
# personal/dev's Application list carries every app (see .chezmoi.toml.tmpl).
if [ "$profile" = "dev-server" ]; then
    assert_absent ".config/wezterm"
    assert_absent ".config/zed"
    assert_absent ".config/zen-profile"
    if [ "$os" = "Darwin" ]; then
        assert_absent "Library/Application Support/Code"
        assert_absent "Library/Application Support/iTerm2"
        assert_absent ".config/aerospace"
        assert_absent ".config/cheatsheet"
    else
        assert_absent ".config/Code"
    fi
else
    assert_file ".config/wezterm/wezterm.lua"
    assert_file ".config/zed/keymap.json"
    assert_file ".config/zed/settings.json"
    # Zen profile files, copied into the random-named profile by a script,
    # see docs/adr/0016-zen-browser-profile-files.md
    assert_file ".config/zen-profile/user.js"
    assert_file ".config/zen-profile/chrome/userChrome.css"
    if [ "$os" = "Darwin" ]; then
        assert_file "Library/Application Support/Code/User/settings.json"
        assert_file "Library/Application Support/iTerm2/DynamicProfiles/Nvim_Tmux_Term.json"
        assert_file ".config/aerospace/aerospace.toml"
        assert_file ".config/aerospace/keys.sh"
        assert_file ".config/cheatsheet/raycast/shortcuts.sh"
    else
        assert_file ".config/Code/User/settings.json"
        assert_absent ".config/aerospace"
        assert_absent ".config/cheatsheet"
    fi
fi

# macOS Application manifest (Homebrew), see
# docs/adr/0006-application-category-and-profile-manifests.md: macOS-only,
# one `brew`/`cask` line per Application of the Profile with a Homebrew
# identifier that mise does not install here (docs/adr/0023-applications-from-one-data-file.md).
if [ "$os" = "Darwin" ]; then
    brewfile="$dest/.config/homebrew/Brewfile"
    assert_file ".config/homebrew/Brewfile"
    while IFS= read -r id; do
        case "$id" in
        cask:*) line="cask \"${id#cask:}\"" ;;
        *) line="brew \"$id\"" ;;
        esac
        if [ -f "$brewfile" ] && grep -qxF "$line" "$brewfile"; then
            ok "Brewfile: $line present"
        else
            bad "Brewfile: $line missing"
        fi
    done < <(native_ids brew)
    # Spot check independent of the data file: CLI tools mise installs stay
    # out of the Brewfile
    for formula in yazi ripgrep; do
        if [ -f "$brewfile" ] && grep -qxF "brew \"$formula\"" "$brewfile"; then
            bad "Brewfile (spot check): $formula should come from mise, not Homebrew"
        else
            ok "Brewfile (spot check): no brew \"$formula\""
        fi
    done
    for formula in neovim tree-sitter-cli; do
        if [ -f "$brewfile" ] && grep -qE "^brew \"$formula\"\$" "$brewfile"; then
            bad "Brewfile: $formula should come from mise (ADR 0013), not Homebrew"
        fi
    done
    if [ "$profile" = "dev-server" ]; then
        if [ -f "$brewfile" ] && grep -q '^cask ' "$brewfile"; then
            bad "Brewfile should have no cask entries for dev-server, has some"
        elif [ -f "$brewfile" ] && grep -q '^tap ' "$brewfile"; then
            bad "Brewfile should have no tap entries for dev-server, has some"
        else
            ok "Brewfile has no cask or tap entries for dev-server"
        fi
    else
        if [ -f "$brewfile" ] && grep -qxF 'cask "wezterm"' "$brewfile"; then
            ok "Brewfile (spot check): cask wezterm present"
        else
            bad "Brewfile (spot check): cask wezterm missing"
        fi
        # Third-party tap trusted for its one cask only (ADR 0018)
        if [ -f "$brewfile" ] && grep -qxF 'tap "nikitabobko/tap", trusted: { casks: ["aerospace"] }' "$brewfile"; then
            ok "Brewfile: nikitabobko/tap trusted for aerospace only"
        else
            bad "Brewfile: nikitabobko/tap line missing or trusted too broadly"
        fi
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
    while IFS= read -r pkg; do
        if [ -f "$aptfile" ] && grep -qxF "$pkg" "$aptfile"; then
            ok "apt-packages.txt: $pkg present"
        else
            bad "apt-packages.txt: $pkg missing"
        fi
    done < <(native_ids apt)
    # CLI tools moved to mise must not be installed twice
    for pkg in git-delta starship neovim fzf zoxide yazi glow bat lazygit tree-sitter-cli ripgrep fd-find eza imagemagick; do
        if [ -f "$aptfile" ] && grep -qxF "$pkg" "$aptfile"; then
            bad "apt-packages.txt: $pkg should come from mise, not apt"
        fi
    done
    if [ "$profile" = "dev-server" ]; then
        if [ -f "$aptfile" ] && grep -qxE 'wezterm|code|zed' "$aptfile"; then
            bad "apt-packages.txt should have no GUI apps for dev-server, has some"
        else
            ok "apt-packages.txt has no GUI apps for dev-server"
        fi
    else
        if [ -f "$aptfile" ] && grep -qxF "code" "$aptfile"; then
            ok "apt-packages.txt (spot check): code present"
        else
            bad "apt-packages.txt (spot check): code missing"
        fi
        if [ -f "$aptfile" ] && grep -qE 'iterm2|windows-terminal' "$aptfile"; then
            bad "apt-packages.txt: iterm2/windows-terminal should never appear (no Linux identifier)"
        fi
    fi
    # JetBrainsMono Nerd Font comes from a chezmoi external on Linux, GUI
    # Profiles only, see docs/adr/0011-nvim-toolchain.md
    if [ "$profile" = "dev-server" ]; then
        assert_absent ".local/share/fonts/JetBrainsMonoNerdFont"
    else
        assert_file ".local/share/fonts/JetBrainsMonoNerdFont/JetBrainsMonoNerdFont-Regular.ttf"
    fi
else
    assert_absent ".config/apt-packages.txt"
fi

# Windows Application manifest (winget) is Windows-only, see
# docs/adr/0006-application-category-and-profile-manifests.md
assert_absent ".config/winget"

# Yazi uses the XDG config path on macOS/Linux.
assert_file ".config/yazi/yazi.toml"
assert_file ".config/yazi/package.toml"

# Global git hooks (docs/adr/0009-global-git-hooks.md): agent-trailer
# filter plus the pass-through to each repo's own hooks.
assert_file ".config/git/hooks/commit-msg"
assert_file ".config/git/hooks/run-repo-hook"

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
# together. .oh-my-zsh is a git-repo external (docs/adr/0015-default-shells.md),
# a third-party clone rather than Source State, so it is left out.
skip_hits=$(find "$dest" -path "$dest/.oh-my-zsh" -prune -o \
    \( -name 'README.md' -o -name 'readme.md' -o -name 'README' \
    -o -name 'LICENSE' -o -name 'CHANGELOG.md' -o -name 'HELP.md' \
    -o -name 'which-key.yaml' -o -name 'Thumbs.db' \
    -o -name 'node_modules' -o -name '__pycache__' -o -name 'venv' \) -print \
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
