#!/usr/bin/env bash

# If not running interactively, don't do anything
[ -z "$PS1" ] && return

# don't put duplicate lines in the history. See bash(1) for more options
# ... or force ignoredups and ignorespace
HISTCONTROL=ignoredups:ignorespace

# append to the history file, don't overwrite it
shopt -s histappend

# for setting history length see HISTSIZE and HISTFILESIZE in bash(1)
HISTSIZE=1000
HISTFILESIZE=2000

# check the window size after each command and, if necessary,
# update the values of LINES and COLUMNS.
shopt -s checkwinsize

# make less more friendly for non-text input files, see lesspipe(1)
[ -x /usr/bin/lesspipe ] && eval "$(SHELL=/bin/sh lesspipe)"

# set variable identifying the chroot you work in (used in the prompt below)
if [ -z "$debian_chroot" ] && [ -r /etc/debian_chroot ]; then
   debian_chroot=$(cat /etc/debian_chroot)
fi

# set a fancy prompt (non-color, unless we know we "want" color)
case "$TERM" in
   xterm-color) color_prompt=yes;;
esac

# uncomment for a colored prompt, if the terminal has the capability; turned
# off by default to not distract the user: the focus in a terminal window
# should be on the output of commands, not on the prompt
force_color_prompt=yes

if [ -n "$force_color_prompt" ]; then
   if [ -x /usr/bin/tput ] && tput setaf 1 >&/dev/null; then
   # We have color support; assume it's compliant with Ecma-48
   # (ISO/IEC-6429). (Lack of such support is extremely rare, and such
   # a case would tend to support setf rather than setaf.)
   color_prompt=yes
   else
   color_prompt=
   fi
fi

parse_git_branch() {
     git branch 2> /dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/(\1)/'
}

if [ "$color_prompt" = yes ]; then
   PS1="\[\033[38;5;248m\]\u\[$(tput sgr0)\]\[\033[38;5;250m\]@\[$(tput sgr0)\]\[\033[38;5;252m\]\h \[$(tput sgr0)\]\[\033[38;5;172m\][\D{%r}] \[$(tput sgr0)\]\[\033[38;5;226m\]\w\[$(tput sgr0)\]\n\[\033[38;5;028m\]\$(parse_git_branch) \[\033[38;5;196m\]\$\[$(tput sgr0)\]\[\033[38;5;129m\] \[$(tput sgr0)\]"
else
   PS1='${debian_chroot:+($debian_chroot)}\u@\h:\w\$ '
fi
unset color_prompt force_color_prompt

# If this is an xterm set the title to user@host:dir
case "$TERM" in
xterm*|rxvt*)
   PS1="\[\e]0;${debian_chroot:+($debian_chroot)}\u@\h: \w\a\]$PS1"
   ;;
*)
   ;;
esac

# Turn on CLI colours
export CLICOLOR=1
# export LSCOLORS=Bhfgcxdxbxegedabagacad
export LSCOLORS=ehhdcxdxbxegedabagacad
export LS_COLORS='di=34;47:ln=36;40:so=32:pi=33:ex=31:bd=34;46:cd=34;43:su=30;41:sg=30;46:tw=30;42:ow=30;43'

# enable color support of ls and also add handy aliases
# if [ -x /usr/bin/dircolors ]; then
#   test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
   alias ls='ls --color=auto'
   alias dir='dir --color=auto'
   alias ll='ls -alF --color=auto'
   alias la='ls -A --color=auto'
   alias l='ls -CF'

   alias grep='grep --color=auto'
   alias fgrep='fgrep --color=auto'
   alias egrep='egrep --color=auto'

   # Useful if tree is not installed
   alias myTree='find . | sed -e "s/[^-][^\/]*\//  |/g" -e "s/|\([^ ]\)/|-\1/"'

   alias n='echo "Node: $(node --version)"; echo "NPM:  $(npm --version)"'

   alias tmux='TERM=screen-256color tmux'

# fi

# Add an "alert" alias for long running commands.  Use like so:
#   sleep 10; alert
alias alert='notify-send --urgency=low -i "$([ $? = 0 ] && echo terminal || echo error)" "$(history|tail -n1|sed -e '\''s/^\s*[0-9]\+\s*//;s/[;&|]\s*alert$//'\'')"'

# Editors
export EDITOR='vim'
export SVN_EDITOR=vim

# Alias definitions.
# You may want to put all your additions into a separate file like
# ~/.bash_aliases, instead of adding them here directly.
# See /usr/share/doc/bash-doc/examples in the bash-doc package.

rmcache () {
   pushd ~/jworg-cs/content-core/
   rm -rf ~/jworg-cs/.sscache/* ~/jworg-cs/.sscache/.cache*
   php cli.php CacheResetTask --entire
   popd
}

# Function to adj volume on raspberry pi
vol () {
   amixer cset numid=1 -- $1%
}

if [ -f ~/.bash_aliases ]; then
   . ~/.bash_aliases
fi

# enable programmable completion features (you don't need to enable
# this, if it's already enabled in /etc/bash.bashrc and /etc/profile
# sources /etc/bash.bashrc).
if [ -f /etc/bash_completion ] && ! shopt -oq posix; then
   . /etc/bash_completion
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


# Custom aliases
alias ag='ag --pager="less -r"'

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion
export PATH=${PATH}:./node_modules/.bin
alias n='echo "Node: $(node --version)"; echo "NPM:  $(npm --version)"'
