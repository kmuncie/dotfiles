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
CONFLICT_FILES=()
for pkg in "${PACKAGES[@]}"; do
    # Use --restow --no to match the actual stow operation
    if ! DRY_OUTPUT=$(stow -d "$DOTFILES_DIR" -t "$HOME" --restow --no --verbose "$pkg" 2>&1); then
        # Match all conflict patterns stow may produce
        while IFS= read -r line; do
            if [[ "$line" =~ \*.*over\ existing\ target\ (.+)\ since ]]; then
                CONFLICT_FILES+=("${BASH_REMATCH[1]}")
            elif [[ "$line" =~ \*\ existing\ target\ is.*:\ (.*) ]]; then
                CONFLICT_FILES+=("${BASH_REMATCH[1]}")
            fi
        done <<< "$DRY_OUTPUT"
    fi
done

if [[ ${#CONFLICT_FILES[@]} -gt 0 ]]; then
    BACKUP_DIR="$HOME/dotfiles_backup_$(date +%Y%m%d_%H%M%S)"
    echo "Conflicts detected. Backing up to: $BACKUP_DIR"
    mkdir -p "$BACKUP_DIR"

    for TARGET in "${CONFLICT_FILES[@]}"; do
        SOURCE="$HOME/$TARGET"
        if [[ -e "$SOURCE" || -L "$SOURCE" ]]; then
            BACKUP_PATH="$BACKUP_DIR/$TARGET"
            mkdir -p "$(dirname "$BACKUP_PATH")"
            echo "  Backing up: $SOURCE -> $BACKUP_PATH"
            mv "$SOURCE" "$BACKUP_PATH"
        fi
    done

    echo ""
else
    echo "No conflicts."
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
