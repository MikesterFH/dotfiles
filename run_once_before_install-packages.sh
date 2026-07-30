#!/usr/bin/env bash
# =============================================================================
# chezmoi run_once_before script: installs prerequisite Bootstrap Packages
# (git, mise) and Docker before any managed dotfiles are applied.
#
# Ported from install.sh's ensure_git/install_mise/install_docker. Only the
# macOS branch is implemented so far; Linux/WSL branches land in a follow-up
# ticket (native Windows uses a separate .ps1 script, since bash doesn't run
# there natively).
# =============================================================================
set -euo pipefail

info() { printf "[INFO]  %s\n" "$*"; }
success() { printf "[OK]    %s\n" "$*"; }
warn() { printf "[WARN]  %s\n" "$*"; }
error() { printf "[ERROR] %s\n" "$*" >&2; }

command_exists() { command -v "$1" &>/dev/null; }

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

# -- Git ----------------------------------------------------------------------

ensure_git() {
  info "Checking git..."

  if command_exists git; then
    success "git already installed ($(git --version))"
    return
  fi

  info "Installing git..."

  if command_exists brew; then
    brew install git
  else
    info "Installing Xcode Command Line Tools (includes git)..."
    xcode-select --install 2>/dev/null || true
    until command_exists git; do
      sleep 5
    done
  fi

  if command_exists git; then
    success "git installed ($(git --version))"
  else
    error "git installation could not be verified"
    return 1
  fi
}

# -- mise -----------------------------------------------------------------------

install_mise() {
  info "Checking mise..."

  if command_exists mise; then
    success "mise already installed ($(mise --version))"
    return
  fi

  info "Installing mise..."

  if command_exists brew; then
    brew install mise
  else
    curl https://mise.run | sh
  fi

  if command_exists mise; then
    success "mise installed ($(mise --version))"
  else
    if [ -x "$HOME/.local/bin/mise" ]; then
      success "mise installed ($("$HOME/.local/bin/mise" --version))"
    else
      error "mise installation could not be verified"
      return 1
    fi
  fi

  warn "Remember to activate mise in your shell RC file."
  warn "  bash: eval \"\$(mise activate bash)\""
  warn "  zsh:  eval \"\$(mise activate zsh)\""
}

# -- Docker ---------------------------------------------------------------------

install_docker() {
  info "Checking Docker..."

  if command_exists docker; then
    success "Docker already installed ($(docker --version))"
    return
  fi

  info "Installing Docker..."

  if command_exists brew; then
    brew install --cask docker
    warn "Docker Desktop installed. Please start it manually from Applications."
  else
    error "Homebrew not found. Install Docker Desktop manually:"
    error "  https://docs.docker.com/desktop/install/mac-install/"
    return
  fi

  if command_exists docker; then
    success "Docker installed ($(docker --version))"
  else
    warn "Docker installed but not yet available in this shell session."
    warn "You may need to start Docker Desktop manually."
  fi
}

main() {
  detect_os

  if [ "$OS" != "macos" ]; then
    error "This bootstrap script currently only supports macOS. OS detected: $OS"
    exit 1
  fi

  ensure_git
  install_mise
  install_docker
}

main "$@"
