# Homebrew initialization
if [ -d "/home/linuxbrew/" ]; then
   eval $(/home/linuxbrew/.linuxbrew/bin/brew shellenv)
elif [ -f /opt/homebrew/bin/brew ]; then
   eval $(/opt/homebrew/bin/brew shellenv)
elif [ -f /usr/local/bin/brew ]; then
   eval $(/usr/local/bin/brew shellenv)
fi

# Source path configurations
if [ -f ~/dotfiles/path.sh ]; then
   source ~/dotfiles/path.sh
fi

# Set EDITOR to nvim if available, otherwise use vim
if command -v nvim >/dev/null 2>&1; then
    export EDITOR='nvim'
else
    export EDITOR='vim'
fi

# Source aliases
if [ -f ~/.aliases ]; then
    source ~/.aliases
fi
