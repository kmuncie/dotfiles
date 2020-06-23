# echo "Loading ${HOME}/.bash_aliases"

export EDITOR='vim'

# enable color support of ls and also add handy aliases
alias ls='ls --color=auto'
alias dir='dir --color=auto'
alias ll='ls -halF --color=auto'
alias la='ls -A --color=auto'
alias l='ls -CF'

alias git='git'

# Open tmux with a named session so tmux-resurrect will overwrite it,
# This relies on having a personal session setup on all machines
# https://github.com/tmux-plugins/tmux-resurrect/issues/321
alias tmux='tmux new -s personal'

# Git fix-up
gfu() {
   git commit --fixup="$1";
   git rebase -i "$1"~1 --autosquash;
}

alias ag='ag --pager="less -r"'
alias grep='grep --color=auto'
alias fgrep='fgrep --color=auto'
alias egrep='egrep --color=auto'

# Useful if tree is not installed
alias myTree='find . | sed -e "s/[^-][^\/]*\//  |/g" -e "s/|\([^ ]\)/|-\1/"'

# Easily check Node and NPM versions
alias n='echo "Node: $(node --version)"; echo "NPM:  $(npm --version)"'
alias npmGlobalList="npm -g list | grep '^\(├─┬\|└─┬\)'"

# Add an "alert" alias for long running commands.  Use like so:
#   sleep 10; alert
alias alert='notify-send --urgency=low -i "$([ $? = 0 ] && (echo terminal; exit 0) || (echo error; exit 1))" "$([ $? = 0 ] && echo Task finished || echo Something went wrong!)" "$(history | sed -n "\$s/^\s*[0-9]\+\s*\(.*\)[;&|]\s*alert\$/\1/p")"'

alias cd..='cd ../'                         # Go back 1 directory level (for fast typers)
alias ..='cd ../'                           # Go back 1 directory level
alias ...='cd ../../'                       # Go back 2 directory levels
alias .3='cd ../../../'                     # Go back 3 directory levels
alias .4='cd ../../../../'                  # Go back 4 directory levels
alias .5='cd ../../../../../'               # Go back 5 directory levels
alias .6='cd ../../../../../../'            # Go back 6 directory levels
alias ~="cd ~"                              # ~:            Go Home
alias c='clear'                             # c:            Clear terminal display

alias neofetch='neofetch --config ~/dotfiles/neofetch.conf'

alias weather='curl wttr.in/10987'

# Personal Latex development
alias watchLatex='latexmk -pdf -pvc -outdir=output main.tex'

# Delete .DS_Store files in a directory recursively
alias rmDS='find . -name '.DS_Store' -type f -delete'
