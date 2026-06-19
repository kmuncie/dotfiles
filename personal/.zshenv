# ------------------------------------------------------------------------------
# ZSHENV - Executed for EVERY zsh: login, interactive, AND non-interactive.
# Sources shared .profile so PATH/env exist even in non-login, non-interactive
# shells (scripts, cron, and editor-spawned shells like Windsurf's Cascade
# terminal). See README "Why PATH is sourced in more than one place".
# ------------------------------------------------------------------------------

# Shared PATH and environment setup. Sourced first so the prepends below survive
# .profile's PATH hard-reset.
if [ -f ~/.profile ]; then
    . ~/.profile
fi

[ -f "$HOME/.cargo/env" ] && . "$HOME/.cargo/env"

alias assume=". assume"
