#!/usr/bin/env bash
# Restores dotfiles from backup created by makesymlinks.sh
# This undoes the symlinks and restores original files

set -e  # Exit on any error

########## Variables

dir="$HOME/dotfiles"                    # dotfiles directory
dotfiles_config="$dir/.dotfiles"        # configuration file listing files to symlink
config_dirs="nvim"                      # config directories to restore

# Allow user to specify backup directory or find the most recent one
if [[ -n "$1" ]]; then
    olddir="$1"
else
    # Find the most recent backup directory
    olddir=$(find "$HOME" -maxdepth 1 -name "dotfiles_old_*" -type d | sort -r | head -n 1)
    if [[ -z "$olddir" ]]; then
        echo "Error: No backup directory found" >&2
        echo "Usage: $0 [backup_directory_path]" >&2
        echo "Available backups:"
        find "$HOME" -maxdepth 1 -name "dotfiles_old_*" -type d | sort -r
        exit 1
    fi
    echo "Using most recent backup: $olddir"
fi

##########

# Verify backup directory exists
if [[ ! -d "$olddir" ]]; then
    echo "Error: Backup directory '$olddir' does not exist" >&2
    echo "Available backups:"
    find "$HOME" -maxdepth 1 -name "dotfiles_old_*" -type d | sort -r
    exit 1
fi

echo "Restoring dotfiles from backup in '$olddir'..."

# Verify .dotfiles config file exists
if [[ ! -f "$dotfiles_config" ]]; then
    echo "Error: Configuration file '$dotfiles_config' does not exist" >&2
    exit 1
fi

# Read files from .dotfiles config (skip comments and empty lines)
mapfile -t files < <(grep -v '^#' "$dotfiles_config" | grep -v '^$')

# Restore each dotfile
for file in "${files[@]}"; do
    target_file="$HOME/.$file"
    backup_file="$olddir/$file"
    
    # Check if backup exists
    if [[ ! -e "$backup_file" ]]; then
        echo "No backup found for '$file', skipping..."
        continue
    fi
    
    # Remove symlink if it exists
    if [[ -L "$target_file" ]]; then
        echo "Removing symlink '$target_file'"
        rm "$target_file"
    elif [[ -e "$target_file" ]]; then
        echo "Warning: '$target_file' exists but is not a symlink, backing up to '$target_file.restore_backup'"
        mv "$target_file" "$target_file.restore_backup"
    fi
    
    # Restore original file
    echo "Restoring '$file' from backup"
    mv "$backup_file" "$target_file"
done

# Restore config directories
if [[ -n "$config_dirs" ]]; then
    echo "Restoring config directories..."
    
    for config_dir in $config_dirs; do
        target_dir="$HOME/.config/$config_dir"
        backup_dir="$olddir/config/$config_dir"
        
        # Check if backup exists
        if [[ ! -e "$backup_dir" ]]; then
            echo "No backup found for config '$config_dir', skipping..."
            continue
        fi
        
        # Remove symlink if it exists
        if [[ -L "$target_dir" ]]; then
            echo "Removing config symlink '$target_dir'"
            rm "$target_dir"
        elif [[ -e "$target_dir" ]]; then
            echo "Warning: '$target_dir' exists but is not a symlink, backing up to '$target_dir.restore_backup'"
            mv "$target_dir" "$target_dir.restore_backup"
        fi
        
        # Restore original directory
        echo "Restoring config '$config_dir' from backup"
        mv "$backup_dir" "$target_dir"
    done
fi

echo "Restore completed successfully!"
echo "Backup directory '$olddir' can now be safely removed if desired."