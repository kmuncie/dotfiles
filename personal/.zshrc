# ------------------------------------------------------------------------------
# ZSHRC - Executed for interactive shells.
# For aliases, functions, shell options, and other interactive settings.
# ------------------------------------------------------------------------------

# ------------------------------------------------------------------------------
# Completion System
# ------------------------------------------------------------------------------
# Initialize the completion system with daily cache rebuild
autoload -Uz compinit
if [[ -n ~/.zcompdump(#qN.mh+24) ]]; then
  compinit
else
  compinit -C
fi

# Case insensitive completion
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'

# Menu selection for completions
zstyle ':completion:*' menu select

# Cache completions
zstyle ':completion:*' use-cache on
zstyle ':completion:*' cache-path ~/.zsh/cache

# ------------------------------------------------------------------------------
# Plugin Manager (Antidote)
# ------------------------------------------------------------------------------
# Hardcoded brew prefix paths to avoid slow $(brew --prefix) subshell
if [[ -f /opt/homebrew/opt/antidote/share/antidote/antidote.zsh ]]; then
  # macOS Apple Silicon
  source /opt/homebrew/opt/antidote/share/antidote/antidote.zsh
elif [[ -f /home/linuxbrew/.linuxbrew/opt/antidote/share/antidote/antidote.zsh ]]; then
  # Linux
  source /home/linuxbrew/.linuxbrew/opt/antidote/share/antidote/antidote.zsh
elif [[ -f /usr/local/opt/antidote/share/antidote/antidote.zsh ]]; then
  # macOS Intel
  source /usr/local/opt/antidote/share/antidote/antidote.zsh
fi

# Load plugins from ~/.zsh_plugins.zsh
# This file is managed by Antidote
source ~/.zsh_plugins.zsh

# ------------------------------------------------------------------------------
# Plugin Configuration (post-load)
# ------------------------------------------------------------------------------
# Configure zsh-autosuggestions to not interfere with tab completion
ZSH_AUTOSUGGEST_CLEAR_WIDGETS+=(expand-or-complete)
ZSH_AUTOSUGGEST_ACCEPT_WIDGETS=(end-of-line vi-end-of-line vi-add-eol)
ZSH_AUTOSUGGEST_PARTIAL_ACCEPT_WIDGETS=(forward-char forward-word emacs-forward-word vi-forward-char vi-forward-word vi-forward-blank-word vi-forward-blank-word-end vi-find-next-char vi-find-next-char-skip)

# ------------------------------------------------------------------------------
# History Configuration
# ------------------------------------------------------------------------------
HISTFILE=~/.zsh_history
HISTSIZE=50000
SAVEHIST=50000
setopt SHARE_HISTORY          # Share history between sessions
setopt EXTENDED_HISTORY       # Save timestamp and duration
setopt HIST_EXPIRE_DUPS_FIRST # Expire duplicate entries first
setopt HIST_IGNORE_DUPS       # Don't record duplicates
setopt HIST_FIND_NO_DUPS      # Don't show duplicates in search

# ------------------------------------------------------------------------------
# Keybindings
# ------------------------------------------------------------------------------
bindkey -e  # Use emacs keybindings (more similar to bash defaults)

# Tab completion
bindkey '^I' expand-or-complete  # Ensure Tab triggers completion

# Set up Ctrl+R search to search from the start of the line
bindkey '^R' history-incremental-pattern-search-backward
bindkey '^S' history-incremental-pattern-search-forward

# ------------------------------------------------------------------------------
# Aliases
# ------------------------------------------------------------------------------
if [ -f ~/.aliases ]; then
    source ~/.aliases
fi

# ------------------------------------------------------------------------------
# Tool-specific Configurations
# ------------------------------------------------------------------------------

# NVM (Node Version Manager)
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && . "$NVM_DIR/bash_completion"

# fzf
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

# oh-my-posh (prompt)
if [ "$TERM_PROGRAM" != "Apple_Terminal" ]; then
  eval "$(oh-my-posh init zsh --config ~/dotfiles/oh-my-posh/hunk.omp.json)"
fi

# Kiro terminal integration
[[ "$TERM_PROGRAM" == "kiro" ]] && . "$(kiro --locate-shell-integration-path zsh)"

# WezTerm shell integration - report current directory via OSC 7
# This enables tab titles to show the current working directory
if [[ "$TERM_PROGRAM" == "WezTerm" ]]; then
   _osc7_cwd() {
      printf '\e]7;file://%s%s\e\\' "$HOST" "$PWD"
   }
   autoload -Uz add-zsh-hook
   add-zsh-hook chpwd _osc7_cwd
   _osc7_cwd
fi

# Rust/Cargo
[ -f "$HOME/.cargo/env" ] && . "$HOME/.cargo/env"

# Profiling - uncomment to use
# zmodload zsh/zprof