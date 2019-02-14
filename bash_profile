#!/usr/bin/env bash

echo "Loading ${HOME}/.bash_profile"

if [ -f ~/.bashrc ]; then
    source ~/.bashrc
fi

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
