#!/usr/bin/env bash
# Minimal bash_profile for server environments - sources bashrc, basic PATH.

if [ -f ~/.bashrc ]; then
    source ~/.bashrc
fi

# Git autocomplete if available
if [ -f ~/dotfiles/.git-autocomplete.sh ]; then
   . ~/dotfiles/.git-autocomplete.sh
fi

# set PATH so it includes user's private bin if it exists
if [ -d "$HOME/bin" ]; then
   export PATH="$HOME/bin:$PATH"
fi

# Set preferred editor
if command -v nvim >/dev/null 2>&1; then
    export EDITOR='nvim'
elif command -v vim >/dev/null 2>&1; then
    export EDITOR='vim'
else
    export EDITOR='vi'
fi
