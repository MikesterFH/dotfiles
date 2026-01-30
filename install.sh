#!/usr/bin/env bash
# =============================================================================
# Dotfiles Bootstrap Script (macOS / Linux / WSL)
# Installs dotfiles (symlinks) and tools (mise, Docker, DevPod)
#
# Usage:
#   bash install.sh                         # Everything (tools + dotfiles)
#   bash install.sh --dotfiles-only         # Only dotfiles, no tools
#   bash install.sh --tools-only            # Only tools, no dotfiles
#   bash install.sh --dotfiles-dir ~/dots   # Custom dotfiles directory
#   curl -fsSL https://raw.githubusercontent.com/MikesterFH/dotfiles/main/install.sh | bash
# =============================================================================
{

set -euo pipefail

DOTFILES_REPO="https://github.com/MikesterFH/dotfiles"
DOTFILES_DIR="${HOME}/.dotfiles"
INSTALL_TOOLS=true
INSTALL_DOTFILES=true

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

command_exists() { command -v "$1" &>/dev/null; }

# -- Step tracking ------------------------------------------------------------

STEP_NAMES=()
STEP_RESULTS=()

run_step() {
  local label="$1"
  local func="$2"

  STEP_NAMES+=("$label")

  set +e
  "$func"
  local rc=$?
  set -e

  if [ $rc -eq 0 ]; then
    STEP_RESULTS+=("passed")
  else
    STEP_RESULTS+=("failed")
  fi

  printf "\n"
}

print_summary() {
  printf "${BOLD}========================================${NC}\n"
  printf "${BOLD}  Summary${NC}\n"
  printf "${BOLD}========================================${NC}\n"
  printf "\n"

  local total=${#STEP_NAMES[@]}
  local passed=0
  local failed=0

  for i in $(seq 0 $((total - 1))); do
    local name="${STEP_NAMES[$i]}"
    local result="${STEP_RESULTS[$i]}"

    if [ "$result" = "passed" ]; then
      printf "  ${GREEN}PASSED${NC}  %s\n" "$name"
      ((passed++)) || true
    else
      printf "  ${RED}FAILED${NC}  %s\n" "$name"
      ((failed++)) || true
    fi
  done

  printf "\n"
  printf "  ${DIM}%d passed, %d failed, %d total${NC}\n" "$passed" "$failed" "$total"
  printf "\n"
}

# -- Help & argument parsing --------------------------------------------------

show_help() {
  cat <<EOF
Usage: install.sh [OPTIONS]

Options:
  --dotfiles-only       Only install dotfiles (skip tools)
  --tools-only          Only install tools (skip dotfiles)
  --dotfiles-dir DIR    Directory to clone dotfiles into (default: ~/.dotfiles)
  -h, --help            Show this help message
EOF
}

parse_args() {
  while [ $# -gt 0 ]; do
    case "$1" in
    --dotfiles-only)
      INSTALL_TOOLS=false
      shift
      ;;
    --tools-only)
      INSTALL_DOTFILES=false
      shift
      ;;
    --dotfiles-dir)
      if [ -z "${2:-}" ]; then
        error "--dotfiles-dir requires a value"
        exit 1
      fi
      DOTFILES_DIR="$2"
      shift 2
      ;;
    -h | --help)
      show_help
      exit 0
      ;;
    *)
      error "Unknown option: $1"
      show_help
      exit 1
      ;;
    esac
  done
}

# -- Platform detection -------------------------------------------------------

detect_os() {
  case "$(uname -s)" in
  Darwin) OS="macos" ;;
  Linux)
    if grep -qiE "microsoft|wsl" /proc/version 2>/dev/null || [ -d /mnt/c ]; then
      OS="wsl"
    else
      OS="linux"
    fi
    ;;
  *)
    error "Unsupported OS: $(uname -s)"
    exit 1
    ;;
  esac
}

detect_arch() {
  case "$(uname -m)" in
  x86_64 | amd64) ARCH="amd64" ;;
  aarch64 | arm64) ARCH="arm64" ;;
  *)
    error "Unsupported architecture: $(uname -m)"
    exit 1
    ;;
  esac
}

detect_linux_distro() {
  DISTRO="unknown"
  if [ -f /etc/os-release ]; then
    # shellcheck disable=SC1091
    . /etc/os-release
    case "${ID:-}" in
    debian | ubuntu | pop | linuxmint | elementary) DISTRO="debian" ;;
    fedora | rhel | centos | rocky | alma) DISTRO="fedora" ;;
    arch | manjaro | endeavouros) DISTRO="arch" ;;
    esac
  fi
}

# -- Git ----------------------------------------------------------------------

ensure_git() {
  info "Checking git..."

  if command_exists git; then
    success "git already installed ($(git --version))"
    return
  fi

  info "Installing git..."

  case "$OS" in
  macos)
    if command_exists brew; then
      brew install git
    else
      info "Installing Xcode Command Line Tools (includes git)..."
      xcode-select --install 2>/dev/null || true
      # Wait for installation to complete
      until command_exists git; do
        sleep 5
      done
    fi
    ;;
  linux | wsl)
    case "$DISTRO" in
    debian)
      sudo apt-get update -qq
      sudo apt-get install -y -qq git
      ;;
    fedora)
      sudo dnf install -y git
      ;;
    arch)
      sudo pacman -Sy --noconfirm git
      ;;
    *)
      error "Cannot auto-install git on this distro. Please install git manually."
      return 1
      ;;
    esac
    ;;
  esac

  if command_exists git; then
    success "git installed ($(git --version))"
  else
    error "git installation could not be verified"
    return 1
  fi
}

# -- Clone dotfiles -----------------------------------------------------------

clone_dotfiles() {
  info "Setting up dotfiles repository..."

  if [ -d "$DOTFILES_DIR" ]; then
    if [ -d "${DOTFILES_DIR}/.git" ]; then
      info "Dotfiles repo already exists at ${DOTFILES_DIR}, updating..."
      if git -C "$DOTFILES_DIR" pull --ff-only; then
        success "Dotfiles updated"
      else
        warn "Could not fast-forward, keeping current state"
      fi
      return
    else
      warn "${DOTFILES_DIR} exists but is not a git repo, backing up..."
      mv "$DOTFILES_DIR" "${DOTFILES_DIR}.bak.$(date +%Y%m%d%H%M%S)"
    fi
  fi

  info "Cloning ${DOTFILES_REPO} into ${DOTFILES_DIR}..."
  git clone "$DOTFILES_REPO" "$DOTFILES_DIR"
  success "Dotfiles cloned to ${DOTFILES_DIR}"
}

# -- Dotfiles installation (auto-discovery) -----------------------------------

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

discover_packages() {
  local dotfiles_dir="$1"
  local packages=()

  # Platform-specific exclusions
  local exclude_packages=()
  case "$OS" in
  macos | linux | wsl)
    exclude_packages+=("windowsTerminal")
    ;;
  esac

  for dir in "${dotfiles_dir}"/*/; do
    [ -d "$dir" ] || continue
    local pkg
    pkg="$(basename "$dir")"

    # Skip non-package directories
    if should_skip "$pkg"; then
      continue
    fi

    # Skip platform-excluded packages
    local excluded=false
    for ex in "${exclude_packages[@]}"; do
      if [ "$pkg" = "$ex" ]; then
        excluded=true
        break
      fi
    done
    [ "$excluded" = true ] && continue

    packages+=("$pkg")
  done

  echo "${packages[*]}"
}

get_target_dir() {
  local package="$1"
  case "$package" in
  bash | zsh | fish)
    echo "${HOME}"
    ;;
  tmux)
    echo "${HOME}"
    ;;
  git)
    echo "${HOME}/.config/git"
    ;;
  nvim)
    echo "${HOME}/.config/nvim"
    ;;
  starship)
    echo "${HOME}/.config"
    ;;
  vscode)
    case "$OS" in
    macos) echo "${HOME}/Library/Application Support/Code/User" ;;
    *) echo "${HOME}/.config/Code/User" ;;
    esac
    ;;
  alacritty)
    echo "${HOME}/.config/alacritty"
    ;;
  wezterm)
    echo "${HOME}/.config/wezterm"
    ;;
  *)
    echo "${HOME}/.config/${package}"
    ;;
  esac
}

should_skip() {
  local name="$1"
  local pattern
  for pattern in "${SKIP_FILES[@]}" "${SKIP_DIRS[@]}"; do
    [[ "$name" == "$pattern" ]] && return 0
  done
  return 1
}

link_package() {
  local package="$1"
  local source_dir="${DOTFILES_DIR}/${package}"
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
    [[ "$skip" == true ]] && continue

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

install_dotfiles() {
  local packages
  packages="$(discover_packages "$DOTFILES_DIR")"

  if [ -z "$packages" ]; then
    warn "No packages found in ${DOTFILES_DIR}"
    return
  fi

  info "Packages: ${packages}"
  info "Source:   ${DOTFILES_DIR}"
  printf "\n"

  local failed=0
  for package in $packages; do
    info "Installing package '${package}'..."
    if ! link_package "$package"; then
      ((failed++)) || true
    fi
  done

  printf "\n"
  if [ $failed -gt 0 ]; then
    warn "${failed} package(s) had issues (see above)"
  else
    success "All dotfiles installed successfully"
  fi
}

# -- mise ---------------------------------------------------------------------

install_mise() {
  info "Checking mise..."

  if command_exists mise; then
    success "mise already installed ($(mise --version))"
    return
  fi

  info "Installing mise..."

  case "$OS" in
  macos)
    if command_exists brew; then
      brew install mise
    else
      curl https://mise.run | sh
    fi
    ;;
  linux | wsl)
    case "$DISTRO" in
    debian)
      sudo apt-get update -qq
      sudo apt-get install -y -qq gpg curl
      sudo install -dm 755 /etc/apt/keyrings
      curl -fsSL https://mise.jdx.dev/gpg-key.pub |
        gpg --dearmor |
        sudo tee /etc/apt/keyrings/mise-archive-keyring.gpg >/dev/null
      echo "deb [signed-by=/etc/apt/keyrings/mise-archive-keyring.gpg arch=$(dpkg --print-architecture)] https://mise.jdx.dev/deb stable main" |
        sudo tee /etc/apt/sources.list.d/mise.list >/dev/null
      sudo apt-get update -qq
      sudo apt-get install -y -qq mise
      ;;
    fedora)
      sudo dnf install -y dnf-plugins-core
      sudo dnf config-manager --add-repo https://mise.jdx.dev/rpm/mise.repo
      sudo dnf install -y mise
      ;;
    arch)
      sudo pacman -Sy --noconfirm mise
      ;;
    *)
      curl https://mise.run | sh
      ;;
    esac
    ;;
  esac

  if command_exists mise; then
    success "mise installed ($(mise --version))"
  else
    # mise may be installed to ~/.local/bin which isn't in PATH yet
    if [ -x "$HOME/.local/bin/mise" ]; then
      success "mise installed ($("$HOME/.local/bin/mise" --version))"
    else
      error "mise installation could not be verified"
      return 1
    fi
  fi

  warn "Remember to activate mise in your shell RC file."
  warn "  bash: echo 'eval \"\$(mise activate bash)\"' >> ~/.bashrc"
  warn "  zsh:  echo 'eval \"\$(mise activate zsh)\"'  >> ~/.zshrc"
  warn "  (dotfiles-cli will handle this when you install your dotfiles)"
}

# -- Docker -------------------------------------------------------------------

install_docker() {
  info "Checking Docker..."

  if command_exists docker; then
    success "Docker already installed ($(docker --version))"
    return
  fi

  info "Installing Docker..."

  case "$OS" in
  macos)
    if command_exists brew; then
      brew install --cask docker
      warn "Docker Desktop installed. Please start it manually from Applications."
    else
      error "Homebrew not found. Install Docker Desktop manually:"
      error "  https://docs.docker.com/desktop/install/mac-install/"
      return
    fi
    ;;
  linux | wsl)
    curl -fsSL https://get.docker.com | sh
    sudo usermod -aG docker "$USER"
    warn "Added $USER to docker group. Log out and back in for this to take effect."
    ;;
  esac

  if command_exists docker; then
    success "Docker installed ($(docker --version))"
  else
    warn "Docker installed but not yet available in this shell session."
    warn "You may need to start Docker Desktop (macOS) or re-login (Linux)."
  fi
}

# -- DevPod -------------------------------------------------------------------

install_devpod() {
  info "Checking DevPod..."

  if command_exists devpod; then
    success "DevPod already installed ($(devpod version))"
    return
  fi

  info "Installing DevPod..."

  local devpod_os devpod_arch devpod_url

  case "$OS" in
  macos) devpod_os="darwin" ;;
  linux | wsl) devpod_os="linux" ;;
  esac

  case "$ARCH" in
  amd64) devpod_arch="amd64" ;;
  arm64) devpod_arch="arm64" ;;
  esac

  devpod_url="https://github.com/loft-sh/devpod/releases/latest/download/devpod-${devpod_os}-${devpod_arch}"

  info "Downloading from ${devpod_url}..."
  curl -fsSL "$devpod_url" -o /tmp/devpod
  sudo install -m 0755 /tmp/devpod /usr/local/bin/devpod
  rm -f /tmp/devpod

  if command_exists devpod; then
    success "DevPod installed ($(devpod version))"
  else
    error "DevPod installation could not be verified"
    return 1
  fi
}

# -- DevPod configuration ----------------------------------------------------

configure_devpod() {
  info "Configuring DevPod..."

  devpod provider add docker 2>/dev/null || true
  devpod provider use docker
  devpod context set-options \
    -o DOTFILES_URL="${DOTFILES_REPO}" \
    -o DOTFILES_SCRIPT=install-devpod-dotfiles.sh

  success "DevPod configured (docker provider, dotfiles URL + install script set)"
  info "Provider list:"
  devpod provider list
}

# -- Git project directories & identities ------------------------------------

GIT_PROJECT_DIRS=(
  "${HOME}/dev/personal"
  "${HOME}/dev/work"
  "${HOME}/dev/client"
)

setup_git_dirs() {
  info "Setting up git project directories..."

  for dir in "${GIT_PROJECT_DIRS[@]}"; do
    if [ -d "$dir" ]; then
      success "$(basename "$dir"): ${dir} (already exists)"
    else
      mkdir -p "$dir"
      success "$(basename "$dir"): ${dir} (created)"
    fi
  done

  # Create config.local.* files if they don't exist yet
  local git_config_dir="${HOME}/.config/git"
  mkdir -p "$git_config_dir"

  local profiles=("personal" "work" "client")
  local missing=()

  for profile in "${profiles[@]}"; do
    local local_config="${git_config_dir}/config.local.${profile}"
    if [ ! -f "$local_config" ]; then
      missing+=("$profile")
    fi
  done

  if [ ${#missing[@]} -gt 0 ]; then
    printf "\n"
    info "Git identity setup needed for: ${missing[*]}"

    for profile in "${missing[@]}"; do
      local local_config="${git_config_dir}/config.local.${profile}"
      printf "\n"
      info "Configure git identity for '${profile}':"

      printf "  Name:  "
      read -r git_name
      printf "  Email: "
      read -r git_email

      if [ -n "$git_name" ] && [ -n "$git_email" ]; then
        git config --file "$local_config" user.name "$git_name"
        git config --file "$local_config" user.email "$git_email"
        success "Created ${local_config}"
      else
        warn "Skipped ${profile} (empty name or email)"
      fi
    done
  else
    success "All git identity configs already exist"
  fi
}

# -- Main ---------------------------------------------------------------------

main() {
  parse_args "$@"

  printf "\n"
  printf "${BOLD}========================================${NC}\n"
  printf "${BOLD}  Dotfiles Bootstrap Installer${NC}\n"
  printf "${BOLD}========================================${NC}\n"
  printf "\n"

  detect_os
  detect_arch
  if [ "$OS" != "macos" ]; then
    detect_linux_distro
  else
    DISTRO="n/a"
  fi

  info "Platform:     ${OS}"
  info "Architecture: ${ARCH}"
  info "Distro:       ${DISTRO}"

  if [ "$INSTALL_DOTFILES" = true ]; then
    info "Dotfiles dir: ${DOTFILES_DIR}"
  fi

  info "Install tools:    ${INSTALL_TOOLS}"
  info "Install dotfiles: ${INSTALL_DOTFILES}"
  printf "\n"

  # -- Git (always needed) --
  run_step "Git" ensure_git

  # -- Tools --
  if [ "$INSTALL_TOOLS" = true ]; then
    run_step "mise" install_mise
    run_step "Docker" install_docker
    run_step "DevPod" install_devpod
    run_step "DevPod config" configure_devpod
  fi

  # -- Dotfiles --
  if [ "$INSTALL_DOTFILES" = true ]; then
    run_step "Clone dotfiles" clone_dotfiles
    run_step "Install dotfiles" install_dotfiles
    run_step "Git project dirs & identities" setup_git_dirs
  fi

  # -- Summary --
  print_summary

  warn "Next steps:"
  if [ "$OS" = "macos" ] && [ "$INSTALL_TOOLS" = true ]; then
    warn "  1. Start Docker Desktop from Applications (if not already running)"
    warn "  2. Activate mise in your shell (see hints above)"
  elif [ "$INSTALL_TOOLS" = true ]; then
    warn "  1. Log out and back in so docker group membership takes effect"
    warn "  2. Activate mise in your shell (see hints above)"
  fi
  if [ "$INSTALL_DOTFILES" = true ]; then
    warn "  - Restart your shell to pick up new dotfiles"
    warn "  - To reconfigure a git identity later, run:"
    warn "      git config --file ~/.config/git/config.local.<profile> user.name \"...\""
    warn "      git config --file ~/.config/git/config.local.<profile> user.email \"...\""
  fi
  printf "\n"
}

main "$@"

}
