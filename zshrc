# User configuration

# AWS Usage tool
aws_assume() {
  source assume $@
  # Serverless (SLS) fails when AWS_PROFILE is set, so we unset it here
  unset AWS_PROFILE
}
alias assume='aws_assume'

# From JT
showSiteCert() {
   SITE="$1";
   openssl s_client -showcerts -servername "${SITE}" -connect "${SITE}":443 2> /dev/null < /dev/null
}

rmcache() {
   pushd ~/jworg-cs/content-core/
   rm -rf ~/jworg-cs/.sscache/* ~/jworg-cs/.sscache/.cache*
   php cli.php CacheResetTask --entire
   popd
}

preload() {
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

smartresize() {
   mogrify -path $3 -filter Triangle -define filter:support=2 -thumbnail $2 -unsharp 0.25x0.08+8.3+0.045 -dither None -posterize 136 -quality 82 -define jpeg:fancy-upsampling=off -define png:compression-filter=5 -define png:compression-level=9 -define png:compression-strategy=1 -define png:exclude-chunk=all -interlace none -colorspace sRGB $1
}

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

[ -f ~/.fzf.bash ] && source ~/.fzf.bash

# export MANPATH="/usr/local/man:$MANPATH"

# You may need to manually set your language environment
# export LANG=en_US.UTF-8

# Preferred editor for local and remote sessions
# if [[ -n $SSH_CONNECTION ]]; then
#   export EDITOR='vim'
# else
#   export EDITOR='mvim'
# fi

# Compilation flags
# export ARCHFLAGS="-arch x86_64"

# Set personal aliases, overriding those provided by oh-my-zsh libs,
# plugins, and themes. Aliases can be placed here, though oh-my-zsh
# users are encouraged to define aliases within the ZSH_CUSTOM folder.
# For a full list of active aliases, run `alias`.
#
# Example aliases
# alias zshconfig="mate ~/.zshrc"
# alias ohmyzsh="mate ~/.oh-my-zsh"

# Enable modern command line editing
bindkey -e  # Use emacs keybindings (more similar to bash defaults)

# Set up history
HISTFILE=~/.zsh_history
HISTSIZE=50000
SAVEHIST=50000
setopt SHARE_HISTORY          # Share history between sessions
setopt EXTENDED_HISTORY       # Save timestamp and duration
setopt HIST_EXPIRE_DUPS_FIRST # Expire duplicate entries first
setopt HIST_IGNORE_DUPS      # Don't record duplicates
setopt HIST_FIND_NO_DUPS     # Don't show duplicates in search

# Set up Ctrl+R search
bindkey '^R' history-incremental-pattern-search-backward
bindkey '^S' history-incremental-pattern-search-forward

# Load oh-my-posh
if [ "$TERM_PROGRAM" != "Apple_Terminal" ]; then
  eval "$(oh-my-posh init zsh --config ~/dotfiles/oh-my-posh/hunk.omp.json)"
fi


# Added by Windsurf
export PATH="/Users/kmuncie/.codeium/windsurf/bin:$PATH"

[[ "$TERM_PROGRAM" == "kiro" ]] && . "$(kiro --locate-shell-integration-path zsh)"
