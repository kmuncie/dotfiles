#!/usr/bin/env bash

echo "Loading ${HOME}/.bashrc"

# Get my great aliases
if [ -f ~/.bash_aliases ]; then
   . ~/.bash_aliases
fi

echo "Doing random things first"

# If not running interactively, don't do anything
[ -z "$PS1" ] && return

# Stop KDE ksshaskpass from running
unset SSH_ASKPASS

# don't put duplicate lines in the history
HISTCONTROL=ignoreboth

# append to the history file, don't overwrite it
shopt -s histappend

# for setting history length see HISTSIZE and HISTFILESIZE in bash(1)
HISTSIZE=5000
HISTFILESIZE=10000

# check the window size after each command and, if necessary,
# update the values of LINES and COLUMNS.
shopt -s checkwinsize

color_prompt=yes
force_color_prompt=yes

echo "Loading colorful PS1 and CLI Colors"

# Kevin's cooool color PS1: User@machine time CWD; branch $
if [ "$color_prompt" = yes ]; then
   PS1="\[\033[38;5;248m\]\u\[$(tput sgr0)\]\[\033[38;5;250m\]@\[$(tput sgr0)\]\[\033[38;5;252m\]\h \[$(tput sgr0)\]\[\033[38;5;172m\][\D{%r}] \[$(tput sgr0)\]\[\033[38;5;226m\]\w\[$(tput sgr0)\]\n\[\033[38;5;196m\]\$\[$(tput sgr0)\]\[\033[38;5;129m\] \[$(tput sgr0)\]"
else
   PS1='${debian_chroot:+($debian_chroot)}\u@\h:\w\$ '
fi

# Turn on CLI colours
export CLICOLOR=1
export LSCOLORS=ehhdcxdxbxegedabagacad
export LS_COLORS='di=34;47:ln=36;40:so=32:pi=33:ex=31:bd=34;46:cd=34;43:su=30;41:sg=30;46:tw=30;42:ow=30;43'

test -e "${HOME}/.iterm2_shell_integration.bash" && source "${HOME}/.iterm2_shell_integration.bash"

echo "Lots of random bash functions now..."

parse_git_branch() {
     git branch 2> /dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/(\1)/'
}

# From JT
showSiteCert ()
{
   SITE="$1";
   openssl s_client -showcerts -servername "${SITE}" -connect "${SITE}":443 2> /dev/null < /dev/null
}

rmcache () {
   pushd ~/jworg-cs/content-core/
   rm -rf ~/jworg-cs/.sscache/* ~/jworg-cs/.sscache/.cache*
   php cli.php CacheResetTask --entire
   popd
}

preload() {
   SEGMENTS='/en'
   if [ "$1" != "" ]; then
      SEGMENTS="$1"
   fi
   URLPATH="/$(whoami)${SEGMENTS}"
   echo "Requesting ${URLPATH}"
   while [ "$(curl -w "%{http_code}" -o /dev/null "http://localhost:8080${URLPATH}")" != "200" ]; do
      sleep 0.1
      echo "Requesting ${URLPATH}"
   done;
   printf "\a"
}

# echo "Enabling bash completion"

# enable programmable completion features (you don't need to enable
# this, if it's already enabled in /etc/bash.bashrc and /etc/profile
# sources /etc/bash.bashrc).
# if [ -f /etc/bash_completion ] && ! shopt -oq posix; then
#    . /etc/bash_completion
# fi

# Mac bash completion
# if [ -f $(brew --prefix)/etc/bash_completion ]; then
#    . $(brew --prefix)/etc/bash_completion
# fi

echo "Serverless completions"

# tabtab source for serverless package
# uninstall by removing these lines or running `tabtab uninstall serverless`
[ -f /Users/kmuncie/.nvm/versions/node/v6.10.3/lib/node_modules/serverless/node_modules/tabtab/.completions/serverless.bash ] && . /Users/kmuncie/.nvm/versions/node/v6.10.3/lib/node_modules/serverless/node_modules/tabtab/.completions/serverless.bash
# tabtab source for sls package
# uninstall by removing these lines or running `tabtab uninstall sls`
[ -f /Users/kmuncie/.nvm/versions/node/v6.10.3/lib/node_modules/serverless/node_modules/tabtab/.completions/sls.bash ] && . /Users/kmuncie/.nvm/versions/node/v6.10.3/lib/node_modules/serverless/node_modules/tabtab/.completions/sls.bash

# tabtab source for serverless package
# uninstall by removing these lines or running `tabtab uninstall serverless`
[ -f /home/kmuncie/.nvm/versions/node/v9.4.0/lib/node_modules/serverless/node_modules/tabtab/.completions/serverless.bash ] && . /home/kmuncie/.nvm/versions/node/v9.4.0/lib/node_modules/serverless/node_modules/tabtab/.completions/serverless.bash
# tabtab source for sls package
# uninstall by removing these lines or running `tabtab uninstall sls`
[ -f /home/kmuncie/.nvm/versions/node/v9.4.0/lib/node_modules/serverless/node_modules/tabtab/.completions/sls.bash ] && . /home/kmuncie/.nvm/versions/node/v9.4.0/lib/node_modules/serverless/node_modules/tabtab/.completions/sls.bash

