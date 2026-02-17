#!/usr/bin/env bash
# One-time cleanup of symlinks created by the old makesymlinks.sh script.
# Only removes symlinks that point into ~/dotfiles/ (safe for other files).

set -e

DOTFILES_DIR="$HOME/dotfiles"
REMOVED=0

echo "Scanning for legacy dotfile symlinks pointing to $DOTFILES_DIR..."
echo ""

# Files that were managed by the old .dotfiles config
LEGACY_FILES=(
    "$HOME/.tmux.conf"
    "$HOME/.zshrc"
    "$HOME/.zprofile"
    "$HOME/.bashrc"
    "$HOME/.bash_profile"
    "$HOME/.aliases"
    "$HOME/.zsh_plugins.txt"
    "$HOME/.vimrc"
    "$HOME/.vim"
    "$HOME/.gitconfig"
    "$HOME/.dir-colors"
    "$HOME/.wezterm.lua"
)

# Config directories that were symlinked
LEGACY_CONFIGS=(
    "$HOME/.config/nvim"
)

for target in "${LEGACY_FILES[@]}" "${LEGACY_CONFIGS[@]}"; do
    if [[ -L "$target" ]]; then
        LINK_TARGET="$(readlink "$target")"
        # Only remove if it points into the dotfiles directory
        if [[ "$LINK_TARGET" == "$DOTFILES_DIR"* ]] || [[ "$LINK_TARGET" == "$DOTFILES_DIR/"* ]]; then
            echo "  Removing: $target -> $LINK_TARGET"
            rm "$target"
            ((REMOVED++))
        else
            echo "  Skipping: $target -> $LINK_TARGET (not a dotfiles symlink)"
        fi
    fi
done

echo ""
if [[ $REMOVED -gt 0 ]]; then
    echo "Removed $REMOVED legacy symlink(s)."
    echo "You can now run ./install.sh to set up the new stow-based symlinks."
else
    echo "No legacy symlinks found. Nothing to clean up."
fi
