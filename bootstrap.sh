#!/usr/bin/env bash
# One-shot fresh-Mac setup: Xcode CLT, Homebrew, brew-managed git, repo clone,
# Brewfile, dotfile symlinks. Curl-able (self-clones) and idempotent.
#
# Fresh machine (no git needed — uses curl + brew's git):
#   curl -fsSL https://raw.githubusercontent.com/kmuncie/dotfiles/master/bootstrap.sh -o /tmp/bootstrap.sh
#   bash /tmp/bootstrap.sh personal
#
# Already cloned: ./bootstrap.sh [personal|server]

set -euo pipefail

PROFILE="${1:-personal}"
REPO_URL="https://github.com/kmuncie/dotfiles.git"   # HTTPS: works keyless on a fresh Mac

# Run from inside the repo if possible; otherwise clone to ~/dotfiles.
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
if [[ -f "$SCRIPT_DIR/install.sh" && -f "$SCRIPT_DIR/Brewfile" ]]; then
    DOTFILES_DIR="$SCRIPT_DIR"
else
    DOTFILES_DIR="$HOME/dotfiles"
fi

log()  { printf '\033[1;34m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m!!!\033[0m %s\n' "$*"; }

# ------------------------------------------------------------------------------
# 1. Xcode Command Line Tools.
# Unavoidable: Homebrew requires it. We do NOT rely on its git for anything —
# step 3 installs a brew-managed git, and the dotfiles PATH (/opt/homebrew/bin
# ahead of /usr/bin) makes brew's git win for all real use. CLT git only ever
# serves Homebrew's own internal plumbing.
# ------------------------------------------------------------------------------

if ! xcode-select -p &> /dev/null; then
    log "Installing Xcode Command Line Tools..."
    xcode-select --install &> /dev/null || true
    warn "A GUI installer opened. Click Install and accept the license."
    warn "Waiting for it to finish (Ctrl-C to abort)..."
    # Block until the install completes so the rest of the script runs in one shot.
    until xcode-select -p &> /dev/null; do
        sleep 10
    done
    log "Xcode Command Line Tools installed."
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
# 3. brew-managed git BEFORE cloning, so the repo is cloned with our git, not
# Apple's. brew shellenv (above) already prepends /opt/homebrew/bin to PATH.
# ------------------------------------------------------------------------------

if [[ "$(command -v git)" != /opt/homebrew/* && "$(command -v git)" != /usr/local/* ]]; then
    log "Installing brew-managed git..."
    brew install git
fi
log "Using git at: $(command -v git)"

# ------------------------------------------------------------------------------
# 4. Clone the repo (if we're not already running from inside it).
# ------------------------------------------------------------------------------

if [[ ! -d "$DOTFILES_DIR/.git" ]]; then
    log "Cloning dotfiles into $DOTFILES_DIR..."
    git clone "$REPO_URL" "$DOTFILES_DIR"
fi

# ------------------------------------------------------------------------------
# 5. Brewfile (formulae, casks, App Store apps)
# ------------------------------------------------------------------------------

log "Installing packages from Brewfile (this takes a while)..."
# Homebrew downloads everything up front and skips the entire install phase if
# any single download fails (e.g. a cask CDN times out), which can leave even
# core tools uninstalled. Two defenses:
#   - HOMEBREW_CURL_RETRIES: retry a failing download instead of giving up.
#   - retry the bundle a few times — downloads are cached, so re-runs are cheap
#     and a flaky CDN usually succeeds on a later pass.
# A failure after all retries is non-fatal: we still want the symlinks + shell
# setup below, and any stragglers can be installed by hand.
export HOMEBREW_CURL_RETRIES=3
bundle_ok=0
for attempt in 1 2 3; do
    if brew bundle --file="$DOTFILES_DIR/Brewfile"; then
        bundle_ok=1
        break
    fi
    warn "brew bundle attempt $attempt failed (often a transient download timeout); retrying..."
done
if [[ "$bundle_ok" -ne 1 ]]; then
    warn "Some Brewfile entries still failed after retries (see output above)."
    warn "Continuing with symlinks + shell setup; install the failed items by hand later."
fi

# ------------------------------------------------------------------------------
# 6. Dotfile symlinks via stow
# ------------------------------------------------------------------------------

# brew bundle aborts its install phase if ANY download fails (e.g. a cask
# download times out), which can leave even stow uninstalled. stow is required
# for the symlinks below, so guarantee it directly.
if ! command -v stow &> /dev/null; then
    log "Ensuring stow is installed..."
    brew install stow
fi

log "Installing '$PROFILE' dotfile symlinks..."
"$DOTFILES_DIR/install.sh" "$PROFILE"

# ------------------------------------------------------------------------------
# 7. Default shell -> zsh (macOS ships zsh as default since Catalina, guard anyway)
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
echo "  - cd $DOTFILES_DIR && ./macos-defaults.sh   # apply system preferences"
echo "  - Open tmux and press 'prefix + I' to install TPM plugins"
echo "  - Sign into 1Password, iCloud, and app accounts"
echo "  - Import GPG/YubiKey for commit signing (docs/gpg-guide.md)"
echo "  - (optional) git -C $DOTFILES_DIR remote set-url origin git@github.com:kmuncie/dotfiles.git  # switch to SSH once keys exist"
echo "  - Open a fresh terminal to pick up the new shell config"
