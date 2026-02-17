#!/usr/bin/env bash
# Bash login config for personal machines.
# Sources shared .profile for PATH and environment, then adds bash-specific bits.

# Shared PATH and environment setup (also sourced by .zprofile)
if [ -f ~/.profile ]; then
    . ~/.profile
fi

if [ -f ~/.bashrc ]; then
    source ~/.bashrc
fi

# Enable bash-completion
[[ -r "/opt/homebrew/etc/profile.d/bash_completion.sh" ]] && . "/opt/homebrew/etc/profile.d/bash_completion.sh"

# Dircolors (GNU coreutils)
test -e ~/.dir-colors && eval "$(dircolors -b ~/.dir-colors)"

# Git autocomplete
if [ -f ~/dotfiles/.git-autocomplete.sh ]; then
   . ~/dotfiles/.git-autocomplete.sh
fi
