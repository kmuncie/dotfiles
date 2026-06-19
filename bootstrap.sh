#!/usr/bin/env bash
# Fresh-Mac setup, dotfiles-first: get a working shell + symlinks in place with
# minimal dependencies, THEN install the full package set as a best-effort step.
# A failed package download can never leave you without your shell/config.
# Curl-able and self-cloning. Idempotent.
#
# Fresh machine (no git needed — uses curl + brew's git):
#   curl -fsSL https://raw.githubusercontent.com/kmuncie/dotfiles/master/bootstrap.sh -o /tmp/bootstrap.sh
#   bash /tmp/bootstrap.sh personal
#
# Already cloned: ./bootstrap.sh [personal|server]

# No `set -e`: failures are handled explicitly so one failed package never
# aborts the run. -u catches unset vars, pipefail surfaces pipe failures.
set -uo pipefail

PROFILE="${1:-personal}"
REPO_URL="https://github.com/kmuncie/dotfiles.git"   # HTTPS: works keyless on a fresh Mac
export HOMEBREW_CURL_RETRIES=3                        # retry flaky downloads instead of failing

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
if [[ -f "$SCRIPT_DIR/install.sh" && -f "$SCRIPT_DIR/Brewfile" ]]; then
    DOTFILES_DIR="$SCRIPT_DIR"
else
    DOTFILES_DIR="$HOME/dotfiles"
fi

log()  { printf '\033[1;34m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m!!!\033[0m %s\n' "$*"; }

# =============================================================================
# PHASE 1 — Seed: the minimum needed before we can place dotfiles.
# =============================================================================

# --- Xcode Command Line Tools (required by Homebrew) ---
if ! xcode-select -p &> /dev/null; then
    log "Installing Xcode Command Line Tools..."
    xcode-select --install &> /dev/null || true
    warn "A GUI installer opened. Click Install and accept the license."
    warn "Waiting for it to finish (Ctrl-C to abort)..."
    until xcode-select -p &> /dev/null; do sleep 10; done
    log "Xcode Command Line Tools installed."
else
    log "Xcode Command Line Tools present."
fi

# --- Homebrew ---
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

# --- git + stow only: the just-enough toolset to clone and symlink dotfiles. ---
# Installed directly (not via the full Brewfile) so a slow or failing bulk
# install can't block core setup. Brew git also means we clone with our git,
# not Apple's CLT git.
for tool in git stow; do
    if ! brew list --formula "$tool" &> /dev/null; then
        log "Installing $tool..."
        brew install "$tool" || warn "Failed to install $tool — later steps may fail."
    fi
done
log "Using git at: $(command -v git)"

# =============================================================================
# PHASE 2 — Dotfiles: clone, symlink, set shell. Machine is usable after this.
# =============================================================================

if [[ ! -d "$DOTFILES_DIR/.git" ]]; then
    log "Cloning dotfiles into $DOTFILES_DIR..."
    git clone "$REPO_URL" "$DOTFILES_DIR"
fi

log "Installing '$PROFILE' dotfile symlinks..."
"$DOTFILES_DIR/install.sh" "$PROFILE"

# Default shell -> zsh (macOS ships zsh, so this needs no Homebrew package).
ZSH_PATH="$(command -v zsh)"
if [[ -n "$ZSH_PATH" && "${SHELL:-}" != "$ZSH_PATH" ]]; then
    log "Setting default shell to zsh ($ZSH_PATH)..."
    grep -q "^$ZSH_PATH$" /etc/shells || echo "$ZSH_PATH" | sudo tee -a /etc/shells > /dev/null
    chsh -s "$ZSH_PATH" || warn "chsh failed; set the shell manually later."
else
    log "Default shell already zsh."
fi

log "Core setup complete — shell and dotfiles are in place."

# =============================================================================
# PHASE 3 — Packages: install everything else. Best-effort; never fatal.
# =============================================================================

log "Installing the full package set from Brewfile (this takes a while)..."
bundle_ok=0
for attempt in 1 2 3; do
    if brew bundle --file="$DOTFILES_DIR/Brewfile"; then
        bundle_ok=1
        break
    fi
    warn "brew bundle attempt $attempt failed (often a transient download issue); retrying..."
done
if [[ "$bundle_ok" -ne 1 ]]; then
    warn "Some Brewfile entries failed after retries. Your shell and dotfiles are"
    warn "unaffected. Re-run later:  brew bundle --file=$DOTFILES_DIR/Brewfile"
    warn "or install the stragglers by hand. See docs/new-device.md for network gotchas."
fi

# =============================================================================
# Done
# =============================================================================
log "Bootstrap complete."
echo
echo "Next steps (see docs/new-device.md):"
echo "  - cd $DOTFILES_DIR && ./macos-defaults.sh   # apply system preferences"
echo "  - Open tmux and press 'prefix + I' to install TPM plugins"
echo "  - Set up SSH via 1Password, then switch the repo to SSH:"
echo "      git -C $DOTFILES_DIR remote set-url origin git@github.com:kmuncie/dotfiles.git"
echo "  - Import GPG/YubiKey for commit signing (docs/gpg-guide.md)"
echo "  - Sign into 1Password, iCloud, and app accounts"
echo "  - Open a fresh terminal to pick up the new shell config"
