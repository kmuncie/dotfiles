# ------------------------------------------------------------------------------
# ZPROFILE - Executed at login for zsh.
# Sources shared .profile for PATH and environment, then adds zsh-specific bits.
# ------------------------------------------------------------------------------

# Shared PATH and environment setup (also sourced by .bash_profile)
if [ -f ~/.profile ]; then
    . ~/.profile
fi
