# ------------------------------------------------------------------------------
# ZPROFILE - Executed at login for zsh.
# Sources shared .profile for PATH and environment, then adds zsh-specific bits.
# ------------------------------------------------------------------------------

# Shared PATH and environment setup (also sourced by .bash_profile)
if [ -f ~/.profile ]; then
    . ~/.profile
fi

# Added by OrbStack: command-line tools and integration
# This won't be added again if you remove it.
source ~/.orbstack/shell/init.zsh 2>/dev/null || :
