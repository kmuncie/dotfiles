# ------------------------------------------------------------------------------
# ZPROFILE - Executed at login.
# For environment variables and commands that should run only once.
# ------------------------------------------------------------------------------

# Set a default PATH
export PATH="/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"

# Homebrew initialization
# Adds Homebrew's bin to the PATH
if [ -d "/home/linuxbrew/" ]; then # Linux
   eval $(/home/linuxbrew/.linuxbrew/bin/brew shellenv)
elif [ -f /opt/homebrew/bin/brew ]; then # Apple Silicon
   eval $(/opt/homebrew/bin/brew shellenv)
elif [ -f /usr/local/bin/brew ]; then # Intel Mac
   eval $(/usr/local/bin/brew shellenv)
fi

# ------------------------------------------------------------------------------
# PATH Additions
# ------------------------------------------------------------------------------

# From `brew install coreutils`:
# ==> Caveats
# Commands also provided by macOS have been installed with the prefix "g".
# If you need to use these commands with their normal names, you
# can add a "gnubin" directory to your PATH from your bashrc like:
# https://stackoverflow.com/questions/57972341/how-to-install-and-use-gnu-ls-on-macos
[ -d "${HOMEBREW_PREFIX}/opt/coreutils/libexec/gnubin" ] && export PATH="${HOMEBREW_PREFIX}/opt/coreutils/libexec/gnubin:${PATH}"

# From `brew install gnu-sed`
# ==> Caveats
# GNU "sed" has been installed as "gsed".
# If you need to use it as "sed", you can add a "gnubin" directory
# to your PATH from your bashrc like:
#     PATH="/usr/local/opt/gnu-sed/libexec/gnubin:$PATH"
[ -d "${HOMEBREW_PREFIX}/opt/gnu-sed/libexec/gnubin" ] && export PATH="${HOMEBREW_PREFIX}/opt/gnu-sed/libexec/gnubin:$PATH"

# From `brew install grep`:
# ==> Caveats
# All commands have been installed with the prefix "g".
# If you need to use these commands with their normal names, you
# can add a "gnubin" directory to your PATH from your bashrc like:
[ -d "${HOMEBREW_PREFIX}/opt/grep/libexec/gnubin" ] && export PATH="${HOMEBREW_PREFIX}/opt/grep/libexec/gnubin:$PATH"

# From `brew install python`
# ==> Caveats
# Unversioned symlinks `python`, `python-config`, `pip` etc. pointing to
# `python3`, `python3-config`, `pip3` etc., respectively, have been installed into
#   /usr/local/opt/python/libexec/bin
[ -d "${HOMEBREW_PREFIX}/opt/python/libexec/bin" ] && export PATH="${HOMEBREW_PREFIX}/opt/python/libexec/bin:$PATH"

# From `brew install openssl@1.1`
# ==> Caveats
# openssl@1.1 is keg-only, which means it was not symlinked into /usr/local,
# because openssl/libressl is provided by macOS so don't link an incompatible version.
[ -d "${HOMEBREW_PREFIX}/opt/openssl@1.1/bin" ] && export PATH="${HOMEBREW_PREFIX}/opt/openssl@1.1/bin:$PATH"

# From `brew install sqlite`
# ==> Caveats
# sqlite is keg-only, which means it was not symlinked into /usr/local,
# because macOS provides an older sqlite3.
[ -d "${HOMEBREW_PREFIX}/opt/sqlite/bin" ] && export PATH="${HOMEBREW_PREFIX}/opt/sqlite/bin:$PATH"

# From `brew install ruby`
# ==> Caveats
# ruby is keg-only, which means it was not symlinked into /usr/local,
# because macOS already provides this software and installing another version in
# parallel can cause all kinds of trouble.
[ -d "${HOMEBREW_PREFIX}/opt/ruby/bin" ] && export PATH="${HOMEBREW_PREFIX}/opt/ruby/bin:$PATH"

# From `brew cask install mactex`
# Not explicitly stated in the install, but you need to add its bin
# folder to the PATH:
if [ -d /Library/TeX/texbin ]; then
   export PATH="/Library/TeX/texbin:$PATH"
fi

# From `brew install openjdk`
# ==> Caveats
# openjdk is keg-only, which means it was not symlinked into /usr/local,
# because it shadows the macOS `java` wrapper.
[ -d "${HOMEBREW_PREFIX}/opt/openjdk/bin" ] && export PATH="${HOMEBREW_PREFIX}/opt/openjdk/bin:$PATH"

## -- Kevin's Additions ------------------------------------------------

# set PATH so it includes user's private bin if it exists
if [ -d "$HOME/bin" ] ; then
   export PATH="$HOME/bin:$PATH"
fi

# Setup Go PATH variables https://linode.com/docs/development/go/install-go-on-ubuntu/
export GOPATH=$HOME/go
export PATH=$PATH:/usr/local/go/bin:$GOPATH/bin

# Setup Flutter PATH variable
[ -d "$HOME/flutter/bin" ] && export PATH="$PATH:$HOME/flutter/bin"

export PATH=${PATH}:./node_modules/.bin

# Added by Windsurf
export PATH="/Users/kmuncie/.codeium/windsurf/bin:$PATH"

# ------------------------------------------------------------------------------
# Environment Variables
# ------------------------------------------------------------------------------

# Set preferred editor
if command -v nvim >/dev/null 2>&1; then
    export EDITOR='nvim'
else
    export EDITOR='vim'
fi

# GPG
export GPG_TTY=$(tty)

# Set MANPATH for coreutils
[ -d "${HOMEBREW_PREFIX}/opt/coreutils/libexec/gnuman" ] && export MANPATH="${HOMEBREW_PREFIX}/opt/coreutils/libexec/gnuman:${MANPATH}"
