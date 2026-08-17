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
# Catppuccin Mocha - zsh-syntax-highlighting
# Must be set before the plugin is sourced via antidote
# https://github.com/catppuccin/zsh-syntax-highlighting
# ------------------------------------------------------------------------------
ZSH_HIGHLIGHT_HIGHLIGHTERS=(main cursor)
typeset -gA ZSH_HIGHLIGHT_STYLES
ZSH_HIGHLIGHT_STYLES[comment]='fg=#585b70'
ZSH_HIGHLIGHT_STYLES[alias]='fg=#a6e3a1'
ZSH_HIGHLIGHT_STYLES[suffix-alias]='fg=#a6e3a1'
ZSH_HIGHLIGHT_STYLES[global-alias]='fg=#a6e3a1'
ZSH_HIGHLIGHT_STYLES[function]='fg=#a6e3a1'
ZSH_HIGHLIGHT_STYLES[command]='fg=#a6e3a1'
ZSH_HIGHLIGHT_STYLES[precommand]='fg=#a6e3a1,italic'
ZSH_HIGHLIGHT_STYLES[autodirectory]='fg=#fab387,italic'
ZSH_HIGHLIGHT_STYLES[single-hyphen-option]='fg=#fab387'
ZSH_HIGHLIGHT_STYLES[double-hyphen-option]='fg=#fab387'
ZSH_HIGHLIGHT_STYLES[back-quoted-argument]='fg=#cba6f7'
ZSH_HIGHLIGHT_STYLES[builtin]='fg=#a6e3a1'
ZSH_HIGHLIGHT_STYLES[reserved-word]='fg=#a6e3a1'
ZSH_HIGHLIGHT_STYLES[hashed-command]='fg=#a6e3a1'
ZSH_HIGHLIGHT_STYLES[commandseparator]='fg=#f38ba8'
ZSH_HIGHLIGHT_STYLES[command-substitution-delimiter]='fg=#cdd6f4'
ZSH_HIGHLIGHT_STYLES[command-substitution-delimiter-unquoted]='fg=#cdd6f4'
ZSH_HIGHLIGHT_STYLES[process-substitution-delimiter]='fg=#cdd6f4'
ZSH_HIGHLIGHT_STYLES[back-quoted-argument-delimiter]='fg=#f38ba8'
ZSH_HIGHLIGHT_STYLES[back-double-quoted-argument]='fg=#f38ba8'
ZSH_HIGHLIGHT_STYLES[back-dollar-quoted-argument]='fg=#f38ba8'
ZSH_HIGHLIGHT_STYLES[command-substitution-quoted]='fg=#f9e2af'
ZSH_HIGHLIGHT_STYLES[command-substitution-delimiter-quoted]='fg=#f9e2af'
ZSH_HIGHLIGHT_STYLES[single-quoted-argument]='fg=#f9e2af'
ZSH_HIGHLIGHT_STYLES[single-quoted-argument-unclosed]='fg=#eba0ac'
ZSH_HIGHLIGHT_STYLES[double-quoted-argument]='fg=#f9e2af'
ZSH_HIGHLIGHT_STYLES[double-quoted-argument-unclosed]='fg=#eba0ac'
ZSH_HIGHLIGHT_STYLES[rc-quote]='fg=#f9e2af'
ZSH_HIGHLIGHT_STYLES[dollar-quoted-argument]='fg=#cdd6f4'
ZSH_HIGHLIGHT_STYLES[dollar-quoted-argument-unclosed]='fg=#eba0ac'
ZSH_HIGHLIGHT_STYLES[dollar-double-quoted-argument]='fg=#cdd6f4'
ZSH_HIGHLIGHT_STYLES[assign]='fg=#cdd6f4'
ZSH_HIGHLIGHT_STYLES[named-fd]='fg=#cdd6f4'
ZSH_HIGHLIGHT_STYLES[numeric-fd]='fg=#cdd6f4'
ZSH_HIGHLIGHT_STYLES[unknown-token]='fg=#eba0ac'
ZSH_HIGHLIGHT_STYLES[path]='fg=#cdd6f4,underline'
ZSH_HIGHLIGHT_STYLES[path_pathseparator]='fg=#f38ba8,underline'
ZSH_HIGHLIGHT_STYLES[path_prefix]='fg=#cdd6f4,underline'
ZSH_HIGHLIGHT_STYLES[path_prefix_pathseparator]='fg=#f38ba8,underline'
ZSH_HIGHLIGHT_STYLES[globbing]='fg=#cdd6f4'
ZSH_HIGHLIGHT_STYLES[history-expansion]='fg=#cba6f7'
ZSH_HIGHLIGHT_STYLES[back-quoted-argument-unclosed]='fg=#eba0ac'
ZSH_HIGHLIGHT_STYLES[redirection]='fg=#cdd6f4'
ZSH_HIGHLIGHT_STYLES[arg0]='fg=#cdd6f4'
ZSH_HIGHLIGHT_STYLES[default]='fg=#cdd6f4'
ZSH_HIGHLIGHT_STYLES[cursor]='fg=#cdd6f4'

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

# Auto-compile .zsh_plugins.txt → .zsh_plugins.zsh when stale, then load
zsh_plugins=~/.zsh_plugins
[[ ${zsh_plugins}.zsh -nt ${zsh_plugins}.txt ]] || antidote bundle <${zsh_plugins}.txt >${zsh_plugins}.zsh
source ${zsh_plugins}.zsh

# ------------------------------------------------------------------------------
# Plugin Configuration (post-load)
# ------------------------------------------------------------------------------
# Configure zsh-autosuggestions to not interfere with tab completion
ZSH_AUTOSUGGEST_CLEAR_WIDGETS+=(expand-or-complete)

# Accept the WHOLE suggestion (bound to End / Ctrl+E by default).
ZSH_AUTOSUGGEST_ACCEPT_WIDGETS=(end-of-line vi-end-of-line vi-add-eol)

# Accept only the NEXT WORD of the suggestion. forward-word is what the right
# arrow runs (see the custom widget in Keybindings) when a suggestion is shown.
ZSH_AUTOSUGGEST_PARTIAL_ACCEPT_WIDGETS=(forward-word emacs-forward-word vi-forward-word vi-forward-word-end vi-forward-blank-word vi-forward-blank-word-end)

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

# Right arrow: accept one WORD of the autosuggestion when one is showing at the
# end of the line; otherwise behave as a normal one-character cursor move. This
# keeps suggestion-acceptance fast (a word per press) without breaking cursor
# navigation when editing inside text you've already typed.
_accept_word_or_forward_char() {
  if [[ -n "$POSTDISPLAY" ]]; then
    zle forward-word
  else
    zle forward-char
  fi
}
zle -N _accept_word_or_forward_char
bindkey '^[[C' _accept_word_or_forward_char  # right arrow (normal cursor mode)
bindkey '^[OC' _accept_word_or_forward_char  # right arrow (application mode)

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
export FZF_DEFAULT_OPTS=" \
--color=bg+:#313244,bg:#1E1E2E,spinner:#F5E0DC,hl:#F38BA8 \
--color=fg:#CDD6F4,header:#F38BA8,info:#CBA6F7,pointer:#F5E0DC \
--color=marker:#B4BEFE,fg+:#CDD6F4,prompt:#CBA6F7,hl+:#F38BA8 \
--color=selected-bg:#45475A \
--color=border:#6C7086,label:#CDD6F4"

# bat
export BAT_THEME="Catppuccin Mocha"

# LS_COLORS via vivid + Catppuccin Mocha
if command -v vivid &>/dev/null; then
  export LS_COLORS="$(vivid generate catppuccin-mocha)"
fi

# Claude Code - per-directory account switching
# ------------------------------------------------------------------------------
# Two Claude accounts on one machine: personal, and work (Bethel). Claude Code
# has no native profile/account flag, but it honours CLAUDE_CONFIG_DIR, which
# relocates the entire config directory -- credentials, settings, session
# history, project state. One config dir per account keeps them fully separate.
#
#   ~/.claude        personal (the historical default; nothing moved)
#   ~/.claude-work   work     (see ~/.claude-work/README.md)
#
# The rule: anything under ~/Code/BETHEL/ uses the work account, everything
# else uses personal.
#
# IMPORTANT: the personal branch UNSETS CLAUDE_CONFIG_DIR rather than pointing
# it at ~/.claude. Those are not equivalent. Unset, Claude Code uses its default
# layout: state in ~/.claude.json (home root) and the Keychain item
# "Claude Code-credentials". Set -- even to that same ~/.claude path -- it
# switches to custom-dir layout: state in ~/.claude/.claude.json and a Keychain
# item suffixed with a hash of the path. Setting it explicitly therefore invents
# an empty third profile that shares your skills and history but is not logged
# in. Verified 2026-08-12.
#
# Why a wrapper function and not a chpwd hook: CLAUDE_CONFIG_DIR is read once,
# when the process starts. Re-exporting it as you `cd` would do nothing to an
# already-running session and would leave you unsure which account a given
# session actually holds. Resolving at launch time is unambiguous. Setting it as
# a command prefix (rather than `export`) also scopes it to that one process
# tree, so subagents and hooks inherit it while the surrounding shell stays
# clean.
#
# To override for a one-off session, any of:
#   CLAUDE_PROFILE=work claude      # single invocation
#   claude-work / claude-personal   # aliases for the same thing
#   export CLAUDE_PROFILE=work      # pin an entire terminal tab
#
# Caveat: IDE extensions launch the binary directly and never source this file.
# They get an unset CLAUDE_CONFIG_DIR, which is exactly the personal account --
# so they behave correctly, they just cannot reach the work account.
CLAUDE_CFG_WORK="$HOME/.claude-work"

claude() {
  local dir="${PWD:A}" use_work=0   # :A resolves symlinks, so a symlinked repo still matches

  case "${CLAUDE_PROFILE:-}" in
    work)     use_work=1 ;;
    personal) use_work=0 ;;
    *)
      # Trailing slash on both sides so ~/Code/BETHELX can never match.
      case "$dir/" in
        "${HOME:A}/Code/BETHEL/"*) use_work=1 ;;
      esac
      ;;
  esac

  if (( use_work )); then
    CLAUDE_CONFIG_DIR="$CLAUDE_CFG_WORK" command claude "$@"
  else
    # `env -u` rather than `command`, so that an inherited or exported
    # CLAUDE_CONFIG_DIR is actively cleared instead of leaking through.
    env -u CLAUDE_CONFIG_DIR claude "$@"
  fi
}

alias claude-work='CLAUDE_PROFILE=work claude'
alias claude-personal='CLAUDE_PROFILE=personal claude'

# oh-my-posh (prompt)
if [ "$TERM_PROGRAM" != "Apple_Terminal" ]; then
  eval "$(oh-my-posh init zsh --config ~/dotfiles/oh-my-posh/catppuccin-mocha.omp.json)"
fi

# Rust/Cargo
[ -f "$HOME/.cargo/env" ] && . "$HOME/.cargo/env"

# Use the 1Password agent for SSH
export SSH_AUTH_SOCK=~/Library/Group\ Containers/2BUA8C4S2C.com.1password/t/agent.sock

# Profiling - uncomment to use
# zmodload zsh/zprof

