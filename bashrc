#!/usr/bin/env bash

# Get my great aliases
if [ -f ~/.bash_aliases ]; then
   . ~/.bash_aliases
fi

# If not running interactively, don't do anything
[ -z "$PS1" ] && return

# don't put duplicate lines in the history
HISTCONTROL=ignoreboth

# append to the history file, don't overwrite it
shopt -s histappend

# for setting history length see HISTSIZE and HISTFILESIZE in bash(1)
HISTSIZE=1000
HISTFILESIZE=2000

# check the window size after each command and, if necessary,
# update the values of LINES and COLUMNS.
shopt -s checkwinsize

color_prompt=yes
force_color_prompt=yes

parse_git_branch() {
     git branch 2> /dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/(\1)/'
}

# Kevin's cooool color PS1: User@machine time CWD; branch $
if [ "$color_prompt" = yes ]; then
   PS1="\[\033[38;5;248m\]\u\[$(tput sgr0)\]\[\033[38;5;250m\]@\[$(tput sgr0)\]\[\033[38;5;252m\]\h \[$(tput sgr0)\]\[\033[38;5;172m\][\D{%r}] \[$(tput sgr0)\]\[\033[38;5;226m\]\w\[$(tput sgr0)\]\n\[\033[38;5;028m\]\$(parse_git_branch) \[\033[38;5;196m\]\$\[$(tput sgr0)\]\[\033[38;5;129m\] \[$(tput sgr0)\]"
else
   PS1='${debian_chroot:+($debian_chroot)}\u@\h:\w\$ '
fi

# Turn on CLI colours
export CLICOLOR=1
export LSCOLORS=ehhdcxdxbxegedabagacad
export LS_COLORS='di=34;47:ln=36;40:so=32:pi=33:ex=31:bd=34;46:cd=34;43:su=30;41:sg=30;46:tw=30;42:ow=30;43'

test -e "${HOME}/.iterm2_shell_integration.bash" && source "${HOME}/.iterm2_shell_integration.bash"

rmcache () {
   pushd ~/jworg-cs/content-core/
   rm -rf ~/jworg-cs/.sscache/* ~/jworg-cs/.sscache/.cache*
   php cli.php CacheResetTask --entire
   popd
}

# enable programmable completion features (you don't need to enable
# this, if it's already enabled in /etc/bash.bashrc and /etc/profile
# sources /etc/bash.bashrc).
if [ -f /etc/bash_completion ] && ! shopt -oq posix; then
   . /etc/bash_completion
fi
# Mac bash completion
if [ -f $(brew --prefix)/etc/bash_completion ]; then
   . $(brew --prefix)/etc/bash_completion
fi

# set PATH so it includes user's private bin if it exists
if [ -d "$HOME/bin" ] ; then
   PATH="$HOME/bin:$PATH"
fi

export PATH="/usr/local/opt/coreutils/libexec/gnubin:$PATH"

# Setup Go PATH variables https://linode.com/docs/development/go/install-go-on-ubuntu/
export GOPATH=$HOME/go
export PATH=$PATH:/usr/local/go/bin:$GOPATH/bin

# if [ -f ~/dotfiles/.git-autocomplete.sh ]; then
#   . ~/dotfiles/.git-autocomplete.sh
# fi

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion
export PATH=${PATH}:./node_modules/.bin
