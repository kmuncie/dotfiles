# dotfiles

My personal dotfiles, managed with [GNU Stow](https://www.gnu.org/software/stow/).

## Profiles

Two profiles are available, each built on a shared `common` package:

- **server** (`common` + `server`) - Minimal bash+vim setup for remote machines. No zsh, no brew dependencies.
- **personal** (`common` + `personal`) - Full desktop setup with zsh, neovim, wezterm, tmux plugins, oh-my-posh, and more.

### Package Contents

| Package | Files |
|---------|-------|
| `common` | `.aliases`, `.gitconfig`, `.dir-colors`, `.vimrc`, `.vim/` |
| `server` | `.bashrc`, `.bash_profile`, `.tmux.conf` |
| `personal` | `.bashrc`, `.bash_profile`, `.zshrc`, `.zprofile`, `.zsh_plugins.txt`, `.tmux.conf`, `.tmux/`, `.config/nvim/`, `.wezterm.lua` |

## Setup

### Prerequisites

Install GNU Stow:
```bash
# macOS
brew install stow

# Debian/Ubuntu
sudo apt install stow

# Fedora
sudo dnf install stow
```

### Migrating from the old makesymlinks.sh

```bash
./cleanup-legacy.sh   # Remove old symlinks safely
./install.sh personal # Install new stow-based symlinks
```

### Fresh Install

```bash
git clone <repo-url> ~/dotfiles
cd ~/dotfiles
./install.sh personal   # or: ./install.sh server
```

The install script will:
1. Check that GNU Stow is installed
2. Dry-run to detect conflicts with existing files
3. Back up any conflicting files to `~/dotfiles_backup_YYYYMMDD_HHMMSS/`
4. Stow the `common` package plus your chosen profile

### Uninstall

```bash
./uninstall.sh personal  # Remove personal profile symlinks
./uninstall.sh server    # Remove server profile symlinks
./uninstall.sh all       # Remove all stow-managed symlinks
```

## Non-Stowed Files

These files live at the repo root and are referenced by path rather than symlinked:

- `oh-my-posh/` - Prompt themes (referenced by zshrc)
- `scripts/` - Utility scripts
- `Brewfile` - Homebrew dependencies (`brew bundle`)
- `themes.gitconfig` - Git delta themes (included by gitconfig)
- `neofetch.conf` - Neofetch config (referenced by alias)
- `.git-autocomplete.sh` - Bash git completion (sourced by bash_profile)

## 2025 Added PGP Public Key Signing

Setup using the following guide:
[YubiKey-Guide](https://github.com/drduh/YubiKey-Guide/tree/3912fc0f204cd0c4113bae38e19f68db8cbfa63c)

## Shell Configuration

This repository uses a structured approach to manage shell settings, splitting
them between `.zprofile` and `.zshrc` to ensure correctness and efficiency.

### `.zprofile` vs. `.zshrc`

   * **`~/.zprofile`**: This file runs **once** at the beginning of a login session.
    It is the correct place for setting environment variables like `PATH`,
    `GOPATH`, and `EDITOR`. These variables are set once and inherited by all
    child processes.

   * **`~/.zshrc`**: This file runs for **every new interactive shell** (e.g.,
    opening a new terminal tab). It is used for settings that apply to the
    interactive experience, such as aliases, functions, keybindings, and the
    shell prompt (`oh-my-posh`).

### How to Modify Your `PATH`

All `PATH` modifications should be made in **`~/.zprofile`**. This prevents your
`PATH` from growing incorrectly with every new terminal window.

To add a new directory to your `PATH`, open `~/dotfiles/personal/.zprofile` and add a new
line in the `PATH Additions` section. Follow the existing format:

  1. **Add a comment** explaining where the new `PATH` entry comes from (e.g.,
     `# From 'brew install my-new-tool'`).
  2. **Add the export command**. It's best practice to check if the directory
     exists before adding it to the `PATH`.

**Example:**

```shell
# From `brew install my-new-tool`
# This tool needs its bin directory in the PATH.
[ -d "/path/to/my-new-tool/bin" ] && export PATH="/path/to/my-new-tool/bin:$PATH"
```

## WezTerm Configuration

WezTerm is configured with a comprehensive setup including appearance
customization, keybindings, project management, and status bar enhancements.

### Features

   * **Nord Color Scheme**: Clean, modern color palette
   * **FantasqueSansMono Nerd Font**: Crisp monospace font with icon support
   * **Transparency & Blur**: Subtle background transparency with macOS blur effect
   * **Leader Key Navigation**: Ctrl+Space leader key for all custom keybindings
   * **Project Management**: Quick project switching with fuzzy search
   * **Workspace Support**: Multiple workspaces with easy switching
   * **Custom Status Bar**: Gradient-styled status bar showing workspace, time, and
    hostname

### Key Bindings

All custom keybindings use the leader key (Ctrl+Space) followed by another key:

   * **Leader + \**: Split horizontally (new pane to the right)
   * **Leader + -**: Split vertically (new pane below)
   * **Leader + h/j/k/l**: Navigate between panes (vim-style)
   * **Leader + r**: Enter resize mode (then use h/j/k/l to resize)
   * **Leader + c**: Close current pane (with confirmation)
   * **Leader + p**: Open project picker (fuzzy search through ~/code directory)
   * **Leader + f**: Show workspace fuzzy finder

### Project Management

The configuration automatically discovers projects in the `~/code` directory and
allows quick switching between them. Each project opens in its own workspace for
better organization.
