#!/usr/bin/env bash
# Installs dotfile symlinks using GNU Stow for the specified profile.
# Usage: ./install.sh <server|personal>

set -e

DOTFILES_DIR="$(cd "$(dirname "$0")" && pwd)"
PROFILE="$1"

# ------------------------------------------------------------------------------
# Ensure Homebrew is on PATH (may be missing if dotfiles were just cleaned up)
# ------------------------------------------------------------------------------

if ! command -v brew &> /dev/null; then
    if [[ -f /opt/homebrew/bin/brew ]]; then
        eval "$(/opt/homebrew/bin/brew shellenv)"
    elif [[ -f /home/linuxbrew/.linuxbrew/bin/brew ]]; then
        eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
    elif [[ -f /usr/local/bin/brew ]]; then
        eval "$(/usr/local/bin/brew shellenv)"
    fi
fi

# ------------------------------------------------------------------------------
# Validation
# ------------------------------------------------------------------------------

if [[ -z "$PROFILE" ]] || [[ "$PROFILE" != "server" && "$PROFILE" != "personal" ]]; then
    echo "Usage: $0 <server|personal>"
    echo ""
    echo "  server   - Minimal bash+vim setup (common + server)"
    echo "  personal - Full desktop setup (common + personal)"
    exit 1
fi

if ! command -v stow &> /dev/null; then
    echo "Error: GNU Stow is not installed."
    echo ""
    echo "Install it with:"
    echo "  macOS:  brew install stow"
    echo "  Debian: sudo apt install stow"
    echo "  Fedora: sudo dnf install stow"
    exit 1
fi

PACKAGES=("common" "$PROFILE")

echo "Installing profile: $PROFILE"
echo "Packages: ${PACKAGES[*]}"
echo ""

# ------------------------------------------------------------------------------
# Dry run to detect conflicts
# ------------------------------------------------------------------------------

echo "Running dry-run to check for conflicts..."
CONFLICTS=""
for pkg in "${PACKAGES[@]}"; do
    if ! DRY_OUTPUT=$(stow -d "$DOTFILES_DIR" -t "$HOME" --no --verbose "$pkg" 2>&1); then
        CONFLICTS+="$DRY_OUTPUT"$'\n'
    fi
done

if [[ -n "$CONFLICTS" ]]; then
    echo "Conflicts detected:"
    echo "$CONFLICTS"

    # Extract conflicting file paths and back them up
    BACKUP_DIR="$HOME/dotfiles_backup_$(date +%Y%m%d_%H%M%S)"
    echo "Backing up conflicting files to: $BACKUP_DIR"
    mkdir -p "$BACKUP_DIR"

    # Parse stow conflict output for existing target paths
    while IFS= read -r line; do
        # Stow conflict lines look like: "* existing target is neither a link nor a directory: .bashrc"
        if [[ "$line" =~ existing\ target.*:\ (.*) ]]; then
            TARGET="${BASH_REMATCH[1]}"
            SOURCE="$HOME/$TARGET"
            if [[ -e "$SOURCE" || -L "$SOURCE" ]]; then
                BACKUP_PATH="$BACKUP_DIR/$TARGET"
                mkdir -p "$(dirname "$BACKUP_PATH")"
                echo "  Backing up: $SOURCE -> $BACKUP_PATH"
                mv "$SOURCE" "$BACKUP_PATH"
            fi
        fi
    done <<< "$CONFLICTS"

    echo ""
fi

# ------------------------------------------------------------------------------
# Stow packages
# ------------------------------------------------------------------------------

for pkg in "${PACKAGES[@]}"; do
    echo "Stowing: $pkg"
    stow -d "$DOTFILES_DIR" -t "$HOME" --restow "$pkg"
done

echo ""
echo "Installation complete! Profile '$PROFILE' is active."
echo "Open a new terminal to pick up the changes."
