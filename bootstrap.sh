#!/usr/bin/env bash
# One-shot fresh-Mac setup: Xcode CLT, Homebrew, Brewfile, dotfile symlinks.
# Idempotent and safe to re-run. Usage: ./bootstrap.sh [personal|server]

set -euo pipefail

PROFILE="${1:-personal}"
DOTFILES_DIR="$(cd "$(dirname "$0")" && pwd)"

log()  { printf '\033[1;34m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m!!!\033[0m %s\n' "$*"; }

# ------------------------------------------------------------------------------
# 1. Xcode Command Line Tools (git, compilers — Homebrew needs them)
# ------------------------------------------------------------------------------

if ! xcode-select -p &> /dev/null; then
    log "Installing Xcode Command Line Tools..."
    xcode-select --install
    warn "Finish the GUI installer, then re-run ./bootstrap.sh"
    exit 0
else
    log "Xcode Command Line Tools present."
fi

# ------------------------------------------------------------------------------
# 2. Homebrew
# ------------------------------------------------------------------------------

if ! command -v brew &> /dev/null; then
    if [[ -x /opt/homebrew/bin/brew ]]; then
        eval "$(/opt/homebrew/bin/brew shellenv)"
    elif [[ -x /usr/local/bin/brew ]]; then
        eval "$(/usr/local/bin/brew shellenv)"
    else
        log "Installing Homebrew..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        eval "$(/opt/homebrew/bin/brew shellenv)"
    fi
else
    log "Homebrew present."
fi

# ------------------------------------------------------------------------------
# 3. Brewfile (formulae, casks, App Store apps)
# ------------------------------------------------------------------------------

log "Installing packages from Brewfile (this takes a while)..."
brew bundle --file="$DOTFILES_DIR/Brewfile"

# ------------------------------------------------------------------------------
# 4. Dotfile symlinks via stow
# ------------------------------------------------------------------------------

log "Installing '$PROFILE' dotfile symlinks..."
"$DOTFILES_DIR/install.sh" "$PROFILE"

# ------------------------------------------------------------------------------
# 5. Default shell -> zsh (macOS ships zsh as default since Catalina, guard anyway)
# ------------------------------------------------------------------------------

ZSH_PATH="$(command -v zsh)"
if [[ "${SHELL:-}" != "$ZSH_PATH" ]]; then
    log "Setting default shell to zsh ($ZSH_PATH)..."
    if ! grep -q "^$ZSH_PATH$" /etc/shells; then
        echo "$ZSH_PATH" | sudo tee -a /etc/shells > /dev/null
    fi
    chsh -s "$ZSH_PATH"
else
    log "Default shell already zsh."
fi

# ------------------------------------------------------------------------------
# Done
# ------------------------------------------------------------------------------

log "Bootstrap complete."
echo
echo "Remaining manual steps (see docs/new-device.md):"
echo "  - Open tmux and press 'prefix + I' to install TPM plugins"
echo "  - Run ./macos-defaults.sh to apply system preferences"
echo "  - Sign into 1Password, iCloud, and app accounts"
echo "  - Import GPG/YubiKey for commit signing (docs/gpg-guide.md)"
echo "  - Open a fresh terminal to pick up the new shell config"
