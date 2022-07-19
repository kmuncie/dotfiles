#!/usr/bin/env bash

# echo "Loading ${HOME}/.bash_profile"

# Enable bash-completion
[[ -r "/opt/homebrew/etc/profile.d/bash_completion.sh" ]] && . "/opt/homebrew/etc/profile.d/bash_completion.sh"

export PATH="/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"

if [ -f ~/.bashrc ]; then
    source ~/.bashrc
fi

# echo "Exporting PATH's"

if [ -f ~/dotfiles/path.sh ]; then
   source ~/dotfiles/path.sh
fi

test -e ~/.dircolors && \
   eval `dircolors -b ~/.dircolors`

# set PATH so it includes user's private bin if it exists
if [ -d "$HOME/bin" ] ; then
   PATH="$HOME/bin:$PATH"
fi

# Setup Go PATH variables https://linode.com/docs/development/go/install-go-on-ubuntu/
export GOPATH=$HOME/go
export PATH=$PATH:/usr/local/go/bin:$GOPATH/bin

if [ -f ~/dotfiles/.git-autocomplete.sh ]; then
   . ~/dotfiles/.git-autocomplete.sh
fi

# Setup Flutter PATH variable
export PATH=$PATH:/home/kmuncie/flutter/bin

export PATH=${PATH}:./node_modules/.bin

# Homebrew checks for Linux, MacOS M1, MacOS x86
if [ -d "/home/linuxbrew/" ]; then
   eval $(/home/linuxbrew/.linuxbrew/bin/brew shellenv)
elif [ -f /opt/homebrew/bin/brew ]; then
   eval $(/opt/homebrew/bin/brew shellenv)
else [ -f /usr/local/bin/brew ];
   eval $(/usr/local/bin/brew shellenv)
fi
