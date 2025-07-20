#!/usr/bin/env bash
# Creates symlinks from the home directory to dotfiles in ~/dotfiles
# Backs up existing dotfiles to ~/dotfiles_old before creating symlinks

set -e  # Exit on any error

########## Variables

dir="$HOME/dotfiles"                    # dotfiles directory
timestamp=$(date +"%Y%m%d_%H%M%S")
olddir="$HOME/dotfiles_old_$timestamp"      # timestamped backup directory
dotfiles_config="$dir/.dotfiles"            # configuration file listing files to symlink
config_dirs="nvim"                          # config directories to symlink to ~/.config/

##########

# Verify dotfiles directory exists
if [[ ! -d "$dir" ]]; then
    echo "Error: Dotfiles directory '$dir' does not exist" >&2
    exit 1
fi

# Verify .dotfiles config file exists
if [[ ! -f "$dotfiles_config" ]]; then
    echo "Error: Configuration file '$dotfiles_config' does not exist" >&2
    exit 1
fi

# Create dotfiles_old in homedir
echo "Creating '$olddir' for backup of any existing dotfiles..."
mkdir -p "$olddir"
mkdir -p "$olddir/config"  # For config directory backups

# Change to the dotfiles directory
echo "Changing to the '$dir' directory..."
cd "$dir" || {
    echo "Error: Failed to change to directory '$dir'" >&2
    exit 1
}

# Read files from .dotfiles config (skip comments and empty lines)
mapfile -t files < <(grep -v '^#' "$dotfiles_config" | grep -v '^$')

# Process each dotfile
for file in "${files[@]}"; do
    source_file="$dir/$file"
    target_file="$HOME/.$file"
    backup_file="$olddir/$file"
    
    # Check if source file exists
    if [[ ! -e "$source_file" ]]; then
        echo "Warning: Source file '$source_file' does not exist, skipping..."
        continue
    fi
    
    # Handle existing target file/symlink
    if [[ -e "$target_file" || -L "$target_file" ]]; then
        echo "Backing up existing '$target_file' to '$backup_file'"
        # Create parent directory for backup if needed
        mkdir -p "$(dirname "$backup_file")"
        mv "$target_file" "$backup_file"
    fi
    
    echo "Creating symlink to '$file' in home directory"
    ln -s "$source_file" "$target_file"
done

# Handle config directories
if [[ -n "$config_dirs" ]]; then
    echo "Processing config directories..."
    
    # Create ~/.config if it doesn't exist
    mkdir -p "$HOME/.config"
    
    for config_dir in $config_dirs; do
        source_dir="$dir/config/$config_dir"
        target_dir="$HOME/.config/$config_dir"
        backup_dir="$olddir/config/$config_dir"
        
        # Check if source config directory exists
        if [[ ! -d "$source_dir" ]]; then
            echo "Warning: Source config directory '$source_dir' does not exist, skipping..."
            continue
        fi
        
        # Handle existing target directory/symlink
        if [[ -e "$target_dir" || -L "$target_dir" ]]; then
            echo "Backing up existing config '$target_dir' to '$backup_dir'"
            # Create parent directory for backup if needed
            mkdir -p "$(dirname "$backup_dir")"
            mv "$target_dir" "$backup_dir"
        fi
        
        echo "Creating symlink to config '$config_dir' in ~/.config/"
        ln -s "$source_dir" "$target_dir"
    done
fi

echo "Symlink creation completed successfully!"
echo "Backup created in: $olddir"
echo "To restore original files, run: ./restoresymlinks.sh with olddir set to: $olddir"
