#!/usr/bin/env bash

# echo "Loading ${HOME}/.bash_profile"

# Enable bash-completion
[[ -r "/opt/homebrew/etc/profile.d/bash_completion.sh" ]] && . "/opt/homebrew/etc/profile.d/bash_completion.sh"


if [ -f ~/.bashrc ]; then
    source ~/.bashrc
fi

# echo "Exporting PATH's"

test -e ~/.dir-colors && \
   eval `dircolors -b ~/.dir-colors`

if [ -f ~/dotfiles/.git-autocomplete.sh ]; then
   . ~/dotfiles/.git-autocomplete.sh
fi

[ -f "$HOME/.cargo/env" ] && . "$HOME/.cargo/env"
