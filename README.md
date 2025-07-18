# dotfiles
My personal dotfiles

makesymlinks.sh will find exsiting dotfiles, archive them, and them symlink dotfiles listed in a whitelist from this directory

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
