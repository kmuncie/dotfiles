#!/usr/bin/env bash

# echo "Loading ${HOME}/.bash_profile"

export PATH="/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"

if [ -f ~/.bashrc ]; then
    source ~/.bashrc
fi

# echo "Exporting PATH's"

if [ -f ~/dotfiles/path.sh ]; then
   source ~/dotfiles/path.sh
fi

# set PATH so it includes user's private bin if it exists
if [ -d "$HOME/bin" ] ; then
   PATH="$HOME/bin:$PATH"
fi

export PATH="/usr/local/opt/coreutils/libexec/gnubin:$PATH"

# Setup Go PATH variables https://linode.com/docs/development/go/install-go-on-ubuntu/
export GOPATH=$HOME/go
export PATH=$PATH:/usr/local/go/bin:$GOPATH/bin

if [ -f ~/dotfiles/.git-autocomplete.sh ]; then
   . ~/dotfiles/.git-autocomplete.sh
fi

# Setup Flutter PATH variable
export PATH=$PATH:/home/kmuncie/flutter/bin

export PATH=${PATH}:./node_modules/.bin

# Homebrew on linux
if [ -d "/home/linuxbrew/" ]; then
   eval $(/home/linuxbrew/.linuxbrew/bin/brew shellenv)
fi
