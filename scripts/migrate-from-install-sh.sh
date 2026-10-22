#!/usr/bin/env bash
# =============================================================================
# One-time migration: removes symlinks created by the old install.sh, so
# chezmoi's copy+apply model doesn't collide with them on first apply.
#
# Run this once, manually, on any machine that previously ran install.sh --
# immediately before that machine's first `chezmoi init --apply`. Safe to
# run on a machine that never ran install.sh (no-op).
#
# The target paths below are install.sh's own get_target_dir()/
# discover_packages() logic and file listing, applied by hand -- this is a
# fixed historical fact independent of the new chezmoi layout, not something
# this script re-derives at runtime (the old bash/zsh/tmux/... source
# folders it once symlinked from no longer exist in this repo).
# =============================================================================
set -euo pipefail

info() { printf "[INFO]  %s\n" "$*"; }
success() { printf "[OK]    %s\n" "$*"; }
warn() { printf "[WARN]  %s\n" "$*"; }

BACKUP_SUFFIX=".dotfiles-migration-bak.$(date +%Y%m%d%H%M%S)"
removed=0
backed_up=0
skipped=0
left_alone=0

# get_target_dir(vscode) was OS-conditional in install.sh.
case "$(uname -s)" in
Darwin) VSCODE_USER_DIR="${HOME}/Library/Application Support/Code/User" ;;
*) VSCODE_USER_DIR="${HOME}/.config/Code/User" ;;
esac

# $1: target path install.sh would have symlinked.
# $2: expected suffix of that symlink's own target, i.e. the old repo's
#     "<package>/<relative-path>" -- so a symlink that happens to sit at the
#     right path but points somewhere else entirely (not this repo's old
#     layout) is left alone rather than assumed to be install.sh's doing.
handle_path() {
  local path="$1"
  local expected_suffix="$2"
  if [ -L "$path" ]; then
    local link_target
    link_target="$(readlink "$path")"
    case "$link_target" in
    *"$expected_suffix")
      rm "$path"
      info "removed symlink: $path -> $link_target"
      ((removed++)) || true
      ;;
    *)
      warn "symlink at $path points to '$link_target', not this repo's old layout -- left alone"
      ((left_alone++)) || true
      ;;
    esac
  elif [ -e "$path" ]; then
    mv "$path" "${path}${BACKUP_SUFFIX}"
    warn "backed up (not a symlink, left alone otherwise): $path -> ${path}${BACKUP_SUFFIX}"
    ((backed_up++)) || true
  else
    ((skipped++)) || true
  fi
}

# bash (get_target_dir: $HOME)
handle_path "${HOME}/.bashrc" "bash/.bashrc"
handle_path "${HOME}/.bash_aliases" "bash/.bash_aliases"

# zsh (get_target_dir: $HOME)
handle_path "${HOME}/.zshrc" "zsh/.zshrc"
handle_path "${HOME}/.zprofile" "zsh/.zprofile"
handle_path "${HOME}/.zsh_aliases" "zsh/.zsh_aliases"

# tmux (get_target_dir: $HOME -- install.sh's tmux.conf target was ~/tmux.conf,
# not ~/.tmux.conf or ~/.config/tmux/tmux.conf; which-key.yaml was in
# install.sh's SKIP_FILES and was never symlinked)
handle_path "${HOME}/tmux.conf" "tmux/tmux.conf"

# git (get_target_dir: ~/.config/git)
handle_path "${HOME}/.config/git/config" "git/config"

# starship (get_target_dir: ~/.config)
handle_path "${HOME}/.config/starship.toml" "starship/starship.toml"

# vscode (get_target_dir: OS-conditional, see VSCODE_USER_DIR above)
handle_path "${VSCODE_USER_DIR}/settings.json" "vscode/settings.json"
handle_path "${VSCODE_USER_DIR}/keybindings.json" "vscode/keybindings.json"

# zed (get_target_dir default case: ~/.config/zed)
handle_path "${HOME}/.config/zed/settings.jsonc" "zed/settings.jsonc"
handle_path "${HOME}/.config/zed/keymap.jsonc" "zed/keymap.jsonc"

# iterm2 (get_target_dir default case: ~/.config/iterm2 -- never actually read
# by iTerm2, but this is where install.sh would have put it)
handle_path "${HOME}/.config/iterm2/Nvim_Tmux_Term.json" "iterm2/Nvim_Tmux_Term.json"

# nvim (get_target_dir: ~/.config/nvim). Only the files install.sh actually
# symlinked -- SKIP_FILES excluded README.md/LICENSE/HELP.md, and nvim's own
# cache/state subdirectories (lazy plugin data, etc.) were never install.sh's
# to manage and are left untouched.
for rel in \
  .neoconf.json init.lua lazy-lock.json lazyvim.json stylua.toml \
  lua/config/autocmds.lua lua/config/keymaps.lua lua/config/lazy.lua lua/config/options.lua \
  lua/plugins/coding.lua lua/plugins/colorscheme.lua lua/plugins/dap.lua lua/plugins/disabled.lua \
  lua/plugins/editor.lua lua/plugins/example.lua lua/plugins/lsp.lua lua/plugins/lualine.lua \
  lua/plugins/luasnip.lua lua/plugins/mason.lua lua/plugins/mini-move.lua lua/plugins/neotree.lua \
  lua/plugins/nvim-cmp.lua lua/plugins/overseer.lua lua/plugins/package-info.lua lua/plugins/test.lua \
  lua/plugins/tmux-nvim.lua lua/plugins/tmux.lua lua/plugins/treesitter.lua lua/plugins/twilight.lua \
  lua/plugins/ui.lua lua/plugins/visual-multi.lua lua/plugins/which-key.lua lua/plugins/window-picker.lua \
  lua/plugins/zenmode.lua; do
  handle_path "${HOME}/.config/nvim/${rel}" "nvim/${rel}"
done

# wezterm (get_target_dir: ~/.config/wezterm). SKIP_FILES excluded
# CHANGELOG.md; .DS_Store was never tracked by git so was never symlinked.
for rel in \
  .stylua.toml cog.toml wezterm.lua \
  config/appearance.lua config/font.lua config/general.lua config/gpu.lua config/init.lua config/tab-bar.lua \
  events/augment-command-palette.lua events/format-tab-title.lua events/format-window-title.lua \
  events/new-tab-button-click.lua events/update-status.lua \
  mappings/default.lua mappings/init.lua mappings/modes.lua \
  picker/colorscheme.lua picker/font-leading.lua picker/font-size.lua picker/font.lua \
  picker/assets/colorschemes/bamboo-light.lua picker/assets/colorschemes/bamboo-multiplex.lua \
  picker/assets/colorschemes/bamboo.lua picker/assets/colorschemes/carbonfox.lua \
  picker/assets/colorschemes/catppuccin-frappe.lua picker/assets/colorschemes/catppuccin-latte.lua \
  picker/assets/colorschemes/catppuccin-macchiato.lua picker/assets/colorschemes/catppuccin-mocha.lua \
  picker/assets/colorschemes/dawnfox.lua picker/assets/colorschemes/dayfox.lua \
  picker/assets/colorschemes/dracula.lua picker/assets/colorschemes/duskfox.lua \
  picker/assets/colorschemes/eldritch.lua picker/assets/colorschemes/future-term.lua \
  picker/assets/colorschemes/hardhacker.lua picker/assets/colorschemes/kanagawa-dragon.lua \
  picker/assets/colorschemes/kanagawa-lotus.lua picker/assets/colorschemes/kanagawa-wave.lua \
  picker/assets/colorschemes/nightfox.lua picker/assets/colorschemes/nordfox.lua \
  picker/assets/colorschemes/poimandres-storm.lua picker/assets/colorschemes/poimandres.lua \
  picker/assets/colorschemes/rose-pine-dawn.lua picker/assets/colorschemes/rose-pine-moon.lua \
  picker/assets/colorschemes/rose-pine.lua picker/assets/colorschemes/terafox.lua \
  picker/assets/colorschemes/tokyonight-day.lua picker/assets/colorschemes/tokyonight-moon.lua \
  picker/assets/colorschemes/tokyonight-night.lua picker/assets/colorschemes/tokyonight-storm.lua \
  picker/assets/font-leadings/font-leadings.lua picker/assets/font-sizes/font-sizes.lua \
  picker/assets/fonts/cascadia-nf.lua picker/assets/fonts/cascadia-pl.lua picker/assets/fonts/caskaydia-cove-nf.lua \
  picker/assets/fonts/comic-shanns-nf.lua picker/assets/fonts/d2-coding-nf.lua picker/assets/fonts/droid-sans-nf.lua \
  picker/assets/fonts/fira-code-nf.lua picker/assets/fonts/hack-nf.lua picker/assets/fonts/jetbrains-mono-nf.lua \
  picker/assets/fonts/maple-mono.lua picker/assets/fonts/monaspace-argon.lua picker/assets/fonts/monaspace-krypton.lua \
  picker/assets/fonts/monaspace-neon.lua picker/assets/fonts/monaspace-radon.lua picker/assets/fonts/monaspace-xenon.lua \
  picker/assets/fonts/pragmasevka-nf.lua picker/assets/fonts/reset.lua picker/assets/fonts/ubuntu-mono-nf.lua \
  picker/assets/fonts/victor-mono.lua \
  utils/fn.lua utils/gpu.lua utils/init.lua \
  utils/class/config.lua utils/class/icon.lua utils/class/init.lua utils/class/layout.lua \
  utils/class/logger.lua utils/class/picker.lua utils/external/inspect.lua; do
  handle_path "${HOME}/.config/wezterm/${rel}" "wezterm/${rel}"
done

printf "\n"
success "${removed} symlink(s) removed, ${backed_up} file(s) backed up, ${skipped} path(s) already absent, ${left_alone} unrecognized symlink(s) left alone"
if [ "$removed" -eq 0 ] && [ "$backed_up" -eq 0 ]; then
  info "Nothing to migrate -- safe to run 'chezmoi init --apply' now."
fi
