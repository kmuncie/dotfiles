#!/usr/bin/env bash
# Removes dotfile symlinks created by GNU Stow.
# Usage: ./uninstall.sh <server|personal|all>

set -e

DOTFILES_DIR="$(cd "$(dirname "$0")" && pwd)"
TARGET="$1"

if [[ -z "$TARGET" ]] || [[ "$TARGET" != "server" && "$TARGET" != "personal" && "$TARGET" != "all" ]]; then
    echo "Usage: $0 <server|personal|all>"
    echo ""
    echo "  server   - Remove server profile symlinks (common + server)"
    echo "  personal - Remove personal profile symlinks (common + personal)"
    echo "  all      - Remove all stow-managed symlinks"
    exit 1
fi

if ! command -v stow &> /dev/null; then
    echo "Error: GNU Stow is not installed."
    exit 1
fi

if [[ "$TARGET" == "all" ]]; then
    PACKAGES=("common" "server" "personal")
else
    PACKAGES=("common" "$TARGET")
fi

echo "Uninstalling packages: ${PACKAGES[*]}"
echo ""

for pkg in "${PACKAGES[@]}"; do
    PKG_DIR="$DOTFILES_DIR/$pkg"
    if [[ -d "$PKG_DIR" ]]; then
        echo "Unstowing: $pkg"
        stow -d "$DOTFILES_DIR" -t "$HOME" -D "$pkg" 2>/dev/null || true
    fi
done

echo ""
echo "Uninstall complete. Symlinks removed."
