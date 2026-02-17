# dotfiles

My personal dotfiles, managed with [GNU Stow](https://www.gnu.org/software/stow/).

## Profiles

Two profiles are available, each built on a shared `common` package:

- **server** (`common` + `server`) - Minimal bash+vim setup for remote machines. No zsh, no brew dependencies beyond stow itself.
- **personal** (`common` + `personal`) - Full desktop setup with zsh, neovim, wezterm, tmux plugins, oh-my-posh, and more.

### Package Contents

| Package | Files |
|---------|-------|
| `common` | `.aliases`, `.gitconfig`, `.dir-colors`, `.vimrc`, `.vim/` |
| `server` | `.bashrc`, `.bash_profile`, `.tmux.conf` |
| `personal` | `.bashrc`, `.bash_profile`, `.zshrc`, `.zprofile`, `.zsh_plugins.txt`, `.tmux.conf`, `.tmux/`, `.config/nvim/`, `.wezterm.lua` |

## Setup

### Server Profile

The server profile only requires GNU Stow (and only at install time to create symlinks):

```bash
# Debian/Ubuntu
sudo apt install stow

# Fedora
sudo dnf install stow

git clone <repo-url> ~/dotfiles
cd ~/dotfiles
./install.sh server
```

### Personal Profile (macOS)

The personal profile assumes macOS with Homebrew. On a fresh machine:

1. **Install Homebrew** (if not already installed):
   ```bash
   /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
   ```

2. **Clone and install dependencies**:
   ```bash
   git clone <repo-url> ~/dotfiles
   cd ~/dotfiles
   brew bundle          # Installs everything from Brewfile
   ```

3. **Install dotfile symlinks**:
   ```bash
   ./install.sh personal
   ```

4. **Set zsh as default shell** (if not already):
   ```bash
   chsh -s $(which zsh)
   ```

5. **Initialize tmux plugins** (first time):
   Open tmux, then press `prefix + I` to install plugins via TPM.

### Key Dependencies (Personal)

These are installed via `brew bundle` from the Brewfile:

| Dependency | Used By |
|------------|---------|
| `stow` | Symlink management |
| `antidote` | Zsh plugin manager (loaded in `.zshrc`) |
| `oh-my-posh` | Zsh prompt theme |
| `neovim` | Editor (LazyVim config in `.config/nvim/`) |
| `wezterm` | Terminal emulator |
| `tmux` | Terminal multiplexer |
| `git-delta` | Git pager (configured in `.gitconfig`) |
| `fzf` | Fuzzy finder |
| `coreutils` | GNU ls, dircolors (used by `.dir-colors`) |
| `gnu-sed` | GNU sed |
| `grep` | GNU grep |
| `gnupg` + `pinentry-mac` | GPG commit signing (YubiKey) |
| `granted` | AWS role assumption (`assume` function) |

### Migrating from the old makesymlinks.sh

```bash
./cleanup-legacy.sh   # Remove old symlinks safely
./install.sh personal # Install new stow-based symlinks
```

### Updating After Changes

The install script is idempotent — safe to re-run at any time:

```bash
./install.sh personal
```

**When you need to re-run:** only when a **new file** is added to a stow package
(e.g. adding `personal/.sometool`). The new file needs a new symlink.

**When you don't need to re-run:** editing existing files. Since stow creates
symlinks, changes to files in the repo are picked up immediately.

### Uninstall

```bash
./uninstall.sh personal  # Remove personal profile symlinks
./uninstall.sh server    # Remove server profile symlinks
./uninstall.sh all       # Remove all stow-managed symlinks
```

## Non-Stowed Files

These files live at the repo root and are referenced by path rather than symlinked:

| File | Purpose |
|------|---------|
| `oh-my-posh/` | Prompt themes (referenced by `.zshrc`) |
| `scripts/` | Utility scripts |
| `Brewfile` | Homebrew dependencies (`brew bundle`) |
| `themes.gitconfig` | Git delta themes (included by `.gitconfig`) |
| `neofetch.conf` | Neofetch config (referenced by alias) |
| `.git-autocomplete.sh` | Bash git completion (sourced by `.bash_profile`) |
| `ascii/` | ASCII art |
| `iterm/` | Legacy iTerm color schemes |
| `terminatorThemes/` | Legacy Terminator themes |

## PGP Commit Signing

Setup using the following guide:
[YubiKey-Guide](https://github.com/drduh/YubiKey-Guide/tree/3912fc0f204cd0c4113bae38e19f68db8cbfa63c)

## Shell Configuration

The personal profile uses a layered approach to shell configuration:

### File Roles

   * **`~/.profile`**: Shared login environment sourced by both `.zprofile` and
    `.bash_profile`. Contains PATH, Homebrew init, environment variables
    (`EDITOR`, `GOPATH`, `GPG_TTY`). This is the single source of truth for
    environment setup — both shells get identical PATH and variables.

   * **`~/.zprofile`**: Zsh login wrapper. Sources `.profile`.

   * **`~/.bash_profile`**: Bash login wrapper. Sources `.profile`, then adds
    bash-specific bits (bash-completion, dircolors, git-autocomplete).

   * **`~/.zshrc`**: Runs for **every interactive zsh**. Aliases, functions,
    keybindings, completion, plugins, prompt.

   * **`~/.bashrc`**: Runs for **every interactive bash**. Aliases, PS1, history.

### How to Modify Your `PATH`

All `PATH` modifications should be made in **`personal/.profile`**. This keeps
PATH consistent across both zsh and bash, and prevents it from growing
incorrectly with every new terminal window.

```shell
# From `brew install my-new-tool`
# This tool needs its bin directory in the PATH.
[ -d "/path/to/my-new-tool/bin" ] && export PATH="/path/to/my-new-tool/bin:$PATH"
```

## WezTerm Configuration

### Key Bindings

All custom keybindings use the leader key (Ctrl+Space) followed by another key:

   * **Leader + \\**: Split horizontally (new pane to the right)
   * **Leader + -**: Split vertically (new pane below)
   * **Leader + h/j/k/l**: Navigate between panes (vim-style)
   * **Leader + r**: Enter resize mode (then use h/j/k/l to resize)
   * **Leader + c**: Close current pane (with confirmation)
   * **Leader + p**: Open project picker (fuzzy search through ~/code directory)
   * **Leader + f**: Show workspace fuzzy finder

### Project Management

The configuration automatically discovers projects in the `~/code` directory and
allows quick switching between them. Each project opens in its own workspace.
