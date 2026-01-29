#!/usr/bin/env bash
set -euo pipefail

# =============================================================================
# Dotfiles Install Script (for DevPod / Devcontainer)
#
# Called by DevPod after cloning the dotfiles repo into the container.
# Creates symlinks from the cloned repo to the correct locations, then
# activates mise and starship in the shell.
# =============================================================================

# -- Colors & helpers ---------------------------------------------------------

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
DIM='\033[2m'
BOLD='\033[1m'
NC='\033[0m'

info() { printf "${BLUE}[INFO]${NC}    %s\n" "$*"; }
success() { printf "${GREEN}[OK]${NC}      %s\n" "$*"; }
warn() { printf "${YELLOW}[WARN]${NC}    %s\n" "$*"; }
error() { printf "${RED}[ERROR]${NC}   %s\n" "$*" >&2; }

# -- Configuration -----------------------------------------------------------

# Repo root = directory containing this script (devpod clones the repo here)
DOTFILES_SOURCE="$(cd "$(dirname "$0")" && pwd)"
HOME_DIR="${HOME}"
CONFIG_DIR="${HOME}/.config"

# Packages to install in the container
PACKAGES=(nvim starship zsh)

# Files to skip
SKIP_FILES=(
  "README.md" "readme.md" "README"
  ".DS_Store" "Thumbs.db"
  ".gitkeep" "LICENSE" "CHANGELOG.md"
  "HELP.md"
)

# Directories to skip
SKIP_DIRS=(
  ".git" ".svn" "node_modules"
  "__pycache__" ".pytest_cache"
  "venv" ".venv"
)

# -- Target path mapping -----------------------------------------------------

get_target_dir() {
  local package="$1"
  case "$package" in
  bash | zsh | fish) echo "${HOME_DIR}" ;;
  nvim) echo "${CONFIG_DIR}/nvim" ;;
  tmux) echo "${HOME_DIR}" ;;
  starship) echo "${CONFIG_DIR}" ;;
  vscode) echo "${CONFIG_DIR}/Code/User" ;;
  *) echo "${CONFIG_DIR}/${package}" ;;
  esac
}

# -- Skip logic --------------------------------------------------------------

should_skip() {
  local name="$1"
  for skip in "${SKIP_FILES[@]}" "${SKIP_DIRS[@]}"; do
    [[ "$name" == "$skip" ]] && return 0
  done
  return 1
}

# -- Symlink creation --------------------------------------------------------

link_package() {
  local package="$1"
  local source_dir="${DOTFILES_SOURCE}/${package}"
  local target_base
  target_base="$(get_target_dir "$package")"

  if [ ! -d "$source_dir" ]; then
    warn "Package directory not found: ${source_dir}"
    return 1
  fi

  local created=0
  local skipped=0

  while IFS= read -r -d '' source_file; do
    local rel_path="${source_file#"${source_dir}/"}"

    # Check if any path component should be skipped
    local skip=false
    IFS='/' read -ra parts <<<"$rel_path"
    for part in "${parts[@]}"; do
      if should_skip "$part"; then
        skip=true
        break
      fi
    done
    $skip && continue

    local target_path="${target_base}/${rel_path}"
    local target_dir
    target_dir="$(dirname "$target_path")"

    mkdir -p "$target_dir"

    if [ -L "$target_path" ]; then
      local current_target
      current_target="$(readlink "$target_path")"
      if [ "$current_target" = "$source_file" ]; then
        ((skipped++)) || true
        continue
      fi
      rm "$target_path"
    elif [ -e "$target_path" ]; then
      mv "$target_path" "${target_path}.dotfiles-bak"
      info "  Backed up ${target_path} -> ${target_path}.dotfiles-bak"
    fi

    ln -s "$source_file" "$target_path"
    printf "  ${DIM}%s -> %s${NC}\n" "$source_file" "$target_path"
    ((created++)) || true

  done < <(find "$source_dir" -type f -print0)

  if [ $created -gt 0 ] || [ $skipped -gt 0 ]; then
    success "${package}: ${created} created, ${skipped} skipped"
  fi
  return 0
}

# -- Shell integration -------------------------------------------------------

setup_shell() {
  info "Setting up shell integration..."

  local zshrc="${HOME_DIR}/.zshrc"

  # mise activation
  if [ -f "$zshrc" ] && ! grep -q 'mise activate zsh' "$zshrc" 2>/dev/null; then
    printf '\n# mise (tool version manager)\neval "$(mise activate zsh)"\n' >>"$zshrc"
    success "Added mise activation to .zshrc"
  fi

  # starship prompt
  if command -v starship &>/dev/null; then
    if [ -f "$zshrc" ] && ! grep -q 'starship init zsh' "$zshrc" 2>/dev/null; then
      printf '\n# starship prompt\neval "$(starship init zsh)"\n' >>"$zshrc"
      success "Added starship init to .zshrc"
    fi
  fi
}

# -- Main ---------------------------------------------------------------------

main() {
  printf "\n"
  printf "${BOLD}========================================${NC}\n"
  printf "${BOLD}  Dotfiles Container Setup${NC}\n"
  printf "${BOLD}========================================${NC}\n"
  printf "\n"

  info "Dotfiles source: ${DOTFILES_SOURCE}"
  info "Home:            ${HOME_DIR}"
  info "Packages:        ${PACKAGES[*]}"
  printf "\n"

  local failed=0
  for package in "${PACKAGES[@]}"; do
    info "Installing package '${package}'..."
    if ! link_package "$package"; then
      ((failed++)) || true
    fi
  done

  printf "\n"
  setup_shell

  printf "\n"
  printf "${BOLD}========================================${NC}\n"
  printf "${BOLD}  Dotfiles Setup Complete${NC}\n"
  printf "${BOLD}========================================${NC}\n"
  printf "\n"

  info "Available tools:"
  command -v mise &>/dev/null && info "  mise:     $(mise --version 2>&1)"
  command -v nvim &>/dev/null && info "  neovim:   $(nvim --version 2>&1 | head -1)"
  command -v lazygit &>/dev/null && info "  lazygit:  $(lazygit --version 2>&1 | head -1)"
  command -v starship &>/dev/null && info "  starship: $(starship --version 2>&1)"
  command -v yazi &>/dev/null && info "  yazi:     $(yazi --version 2>&1)"
  command -v claude &>/dev/null && info "  claude:   $(claude --version 2>&1)"
  command -v node &>/dev/null && info "  node:     $(node --version 2>&1)"
  printf "\n"

  if [ $failed -gt 0 ]; then
    warn "${failed} package(s) had issues (see above)"
  fi
}

main "$@"
