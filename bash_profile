#!/usr/bin/env bash

# echo "Loading ${HOME}/.bash_profile"

# Enable bash-completion
[[ -r "/opt/homebrew/etc/profile.d/bash_completion.sh" ]] && . "/opt/homebrew/etc/profile.d/bash_completion.sh"


if [ -f ~/.bashrc ]; then
    source ~/.bashrc
fi

# echo "Exporting PATH's"

if [ -f ~/dotfiles/path.sh ]; then
   source ~/dotfiles/path.sh
fi

test -e ~/.dircolors && \
   eval `dircolors -b ~/.dircolors`

if [ -f ~/dotfiles/.git-autocomplete.sh ]; then
   . ~/dotfiles/.git-autocomplete.sh
fi

