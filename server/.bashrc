#!/usr/bin/env bash
# Minimal bashrc for server environments - basic prompt, history, and aliases.

# Source shared aliases and functions
if [ -f ~/.aliases ]; then
   . ~/.aliases
fi

# If not running interactively, don't do anything
[ -z "$PS1" ] && return

# Stop KDE ksshaskpass from running
unset SSH_ASKPASS

# don't put duplicate lines in the history
export HISTCONTROL=ignoreboth
export HISTIGNORE=ls:cd:pwd:
export HISTSIZE=10000
export HISTFILESIZE=20000

# append to the history file, don't overwrite it
shopt -s histappend

# check the window size after each command and, if necessary,
# update the values of LINES and COLUMNS.
shopt -s checkwinsize

color_prompt=yes
force_color_prompt=yes

# Colorized PS1 with git branch: time user@host cwd (branch) $
parse_git_branch() {
     git branch 2> /dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/(\1)/'
}

if [ "$color_prompt" = yes ]; then
   PS1="\[$(tput bold)\]\[\033[38;5;8m\]\t\[$(tput sgr0)\] \[$(tput sgr0)\]\[\033[38;5;3m\]\u\[$(tput sgr0)\]@\[$(tput sgr0)\]\[\033[38;5;1m\]\h\[$(tput sgr0)\] \w \[$(tput sgr0)\]\[\033[38;5;6m\]\$(parse_git_branch)\[$(tput sgr0)\]\n\\$ \[$(tput sgr0)\]"
else
   PS1='${debian_chroot:+($debian_chroot)}\u@\h:\w\$ '
fi

# Turn on CLI colours
export TERM="xterm-256color"
export CLICOLOR=1
