#!/usr/bin/env bash

# echo "Loading ${HOME}/.bashrc"

# Get my great aliases
if [ -f ~/.bash_aliases ]; then
   . ~/.bash_aliases
fi

# echo "Doing random things first"

# If not running interactively, don't do anything
[ -z "$PS1" ] && return

# Stop KDE ksshaskpass from running
unset SSH_ASKPASS

# don't put duplicate lines in the history
export HISTCONTROL=ignorebothexport
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

# echo "Loading colorful PS1 and CLI Colors"

# Kevin's cooool color PS1: User@machine time CWD; branch $
# Backup: PS1="\[\033[38;5;248m\]\u\[$(tput sgr0)\]\[\033[38;5;250m\]@\[$(tput sgr0)\]\[\033[38;5;252m\]\h \[$(tput sgr0)\]\[\033[38;5;172m\][\D{%r}] \[$(tput sgr0)\]\[\033[38;5;226m\]\w\[$(tput sgr0)\]\n\[\033[38;5;196m\]\$\[$(tput sgr0)\]\[\033[38;5;129m\] \[$(tput sgr0)\]"
if [ "$color_prompt" = yes ]; then
   PS1="\[\033[38;5;7m\]\u\[$(tput sgr0)\]\[\033[38;5;15m\]@\[$(tput sgr0)\]\[\033[38;5;160m\]\h\[$(tput sgr0)\]\[\033[38;5;15m\] \[$(tput sgr0)\]\[\033[38;5;94m\]\A\[$(tput sgr0)\]\[\033[38;5;15m\] \[$(tput sgr0)\]\[\033[38;5;76m\]\w\[$(tput sgr0)\]\[\033[38;5;15m\]\n\[$(tput sgr0)\]\[\033[38;5;201m\]\\$\[$(tput sgr0)\]\[\033[38;5;15m\] \[$(tput sgr0)\]"
else
   PS1='${debian_chroot:+($debian_chroot)}\u@\h:\w\$ '
fi

# Turn on CLI colours
export CLICOLOR=1
export LSCOLORS=ehhdcxdxbxegedabagacad
export LS_COLORS='di=34;47:ln=36;40:so=32:pi=33:ex=31:bd=34;46:cd=34;43:su=30;41:sg=30;46:tw=30;42:ow=30;43'

test -e "${HOME}/.iterm2_shell_integration.bash" && source "${HOME}/.iterm2_shell_integration.bash"

# echo "Lots of random bash functions now..."

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

preload () {
   SEGMENTS='/en';
   SITE="$(whoami)";
   if [ "$1" != "" ]; then
      SEGMENTS="$1";
   fi;
   if [ "$2" != "" ]; then
      SITE="$2";
   fi;
   URLPATH="/${SITE}${SEGMENTS}";
   echo "Requesting ${URLPATH}";
   PRELOAD_HTTP_STATUS_CODE="$(curl -w "%{http_code}" -o /dev/null "http://localhost:8080${URLPATH}")";
   while [ $PRELOAD_HTTP_STATUS_CODE == "504" ] || [ $PRELOAD_HTTP_STATUS_CODE == "503" ]; do
      sleep 0.1;
      echo "Received Error Code ${PRELOAD_HTTP_STATUS_CODE}";
      echo "Requesting ${URLPATH}";
      PRELOAD_HTTP_STATUS_CODE="$(curl -L -w "%{http_code}" -o /dev/null "http://localhost:8080${URLPATH}")";
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


export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

# Starship https://starship.rs/
if [ -d "/usr/local/bin/starship" ]; then
   eval "$(starship init bash)"
fi

# tabtab source for packages
# uninstall by removing these lines
[ -f ~/.config/tabtab/__tabtab.bash ] && . ~/.config/tabtab/__tabtab.bash || true
