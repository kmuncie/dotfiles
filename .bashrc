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
# force_color_prompt=yes

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

if [ "$color_prompt" = yes ]; then
   PS1=" \[$(tput sgr0)\]\[\033[38;5;238m\]\u\[$(tput sgr0)\]\[\033[38;5;242m\]@\[$(tput sgr0)\]\[\033[38;5;249m\]\h\[$(tput sgr0)\]\[\033[38;5;243m\]:\[$(tput bold)\]\[$(tput sgr0)\]\[\033[38;5;202m\]\w\[$(tput sgr0)\]\[$(tput sgr0)\]\[\033[38;5;243m\]\\$\[$(tput sgr0)\]"
else
   PS1='${debian_chroot:+($debian_chroot)}\u@\h:\w\$ '
fi
unset color_prompt force_color_prompt

# Custom Colors from bashrcgenerator.com
export PS1="\[\033[38;5;238m\]\u\[$(tput sgr0)\]\[\033[38;5;242m\]@\[$(tput sgr0)\]\[\033[38;5;249m\]\h\[$(tput sgr0)\]\[\033[38;5;243m\]:\[$(tput bold)\]\[$(tput sgr0)\]\[\033[38;5;202m\]\w\[$(tput sgr0)\]\[$(tput sgr0)\]\[\033[38;5;243m\]\\$\[$(tput sgr0)\]"

# If this is an xterm set the title to user@host:dir
case "$TERM" in
xterm*|rxvt*)
   PS1="\[\e]0;${debian_chroot:+($debian_chroot)}\u@\h: \w\a\]$PS1"
   ;;
*)
   ;;
esac

# enable color support of ls and also add handy aliases
if [ -x /usr/bin/dircolors ]; then
   test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
   alias ls='ls --color=auto'
   #alias dir='dir --color=auto'
   #alias vdir='vdir --color=auto'

   alias grep='grep --color=auto'
   alias fgrep='fgrep --color=auto'
   alias egrep='egrep --color=auto'
fi

# Turn on CLI colours
export CLICOLOR=1

# some more ls aliases
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'

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

# Git autocompletion
if [ -d ~/cms-team/settings/ ]; then
   source ~/cms-team/settings/git-completion.sh
fi

# Custom aliases
alias gitco='bgit -p ~/jworg-cs --verbose --checkout'
alias gitup='bgit -p ~/jworg-cs --verbose --update'
alias ag='ag --pager="less -r"'