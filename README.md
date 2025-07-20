# dotfiles
My personal dotfiles

## Setup Scripts

### makesymlinks.sh
Creates symlinks from the home directory to dotfiles in this repository. Safely backs up any existing dotfiles before creating symlinks.

**Features:**
- Timestamped backups prevent overwrites on multiple runs
- Handles both individual dotfiles and config directories
- Preserves directory structure in backups
- Safe error handling with detailed logging

**Usage:**
```bash
./makesymlinks.sh
```

The script will:
1. Read the list of files to symlink from `.dotfiles`
2. Create a timestamped backup directory (e.g., `~/dotfiles_old_20250720_143022`)
3. Back up any existing dotfiles to the backup directory
4. Create symlinks from `~/.filename` to `~/dotfiles/filename`

### restoresymlinks.sh
Restores original dotfiles from backups created by `makesymlinks.sh`. This completely undoes the symlink setup.

**Usage:**
```bash
# Restore from most recent backup automatically
./restoresymlinks.sh

# Restore from specific backup
./restoresymlinks.sh ~/dotfiles_old_20250720_143022
```

The script will:
1. Find the most recent backup (or use specified path)
2. Remove symlinks created by makesymlinks.sh
3. Restore original files from the backup
4. Preserve any files that aren't symlinks by backing them up

### Configuration

Dotfiles to be symlinked are listed in `.dotfiles` (one per line, comments start with #).

## 2025 Added PGP Public Key Signing

Setup using the following guide:
https://github.com/drduh/YubiKey-Guide/tree/3912fc0f204cd0c4113bae38e19f68db8cbfa63c

## 2023 Migration to ZSH

- `chsh -s $(which zsh)`
- Install [oh-my-zsh](https://ohmyz.sh/)
- Install [antigen](https://github.com/zsh-users/antigen) for better package management
- Install [Powerlevel10k](https://github.com/romkatv/powerlevel10k) theme

## WezTerm Configuration

WezTerm is configured with a comprehensive setup including appearance customization, keybindings, project management, and status bar enhancements.

### Features

- **Nord Color Scheme**: Clean, modern color palette
- **FantasqueSansMono Nerd Font**: Crisp monospace font with icon support
- **Transparency & Blur**: Subtle background transparency with macOS blur effect
- **Leader Key Navigation**: Ctrl+Space leader key for all custom keybindings
- **Project Management**: Quick project switching with fuzzy search
- **Workspace Support**: Multiple workspaces with easy switching
- **Custom Status Bar**: Gradient-styled status bar showing workspace, time, and hostname

### Key Bindings

All custom keybindings use the leader key (Ctrl+Space) followed by another key:

- **Leader + \\**: Split horizontally (new pane to the right)
- **Leader + -**: Split vertically (new pane below)
- **Leader + h/j/k/l**: Navigate between panes (vim-style)
- **Leader + r**: Enter resize mode (then use h/j/k/l to resize)
- **Leader + c**: Close current pane (with confirmation)
- **Leader + p**: Open project picker (fuzzy search through ~/code directory)
- **Leader + f**: Show workspace fuzzy finder

### Project Management

The configuration automatically discovers projects in the `~/code` directory and allows quick switching between them. Each project opens in its own workspace for better organization.
