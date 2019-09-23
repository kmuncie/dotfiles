#!/usr/bin/env bash

echo "Loading ${HOME}/.bash_profile"

export PATH="/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"

if [ -f ~/.bashrc ]; then
    source ~/.bashrc
fi

echo "Exporting PATH's"

source ~/dotfiles/path.sh

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

#######################################
# PATH setup added for WOL dev on MacOS
export GEM_HOME="$HOME/.gem"

export LDFLAGS="-L/usr/local/opt/ruby/lib"
export CPPFLAGS="-I/usr/local/opt/ruby/include"

[[ -s "$HOME/.rvm/scripts/rvm" ]] && source "$HOME/.rvm/scripts/rvm" # Load RVM into a shell session *as a function*
export PATH="/usr/local/opt/ruby/bin:$PATH"
export PATH="$GEM_HOME/ruby/2.6.0/bin:$PATH"

# Setting PATH for Python 3.5
# The original version is saved in .bash_profile.pysave
PATH="/Library/Frameworks/Python.framework/Versions/3.5/bin:${PATH}"
export PATH
export PATH="/usr/local/opt/php@7.1/bin:$PATH"
export PATH="/usr/local/opt/php@7.1/sbin:$PATH"

# Add RVM to PATH for scripting. Make sure this is the last PATH variable change.
export PATH="$PATH:$HOME/.rvm/bin"
eval $(/home/linuxbrew/.linuxbrew/bin/brew shellenv)
