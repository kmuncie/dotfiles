#!/usr/bin/env bash

echo "Loading ${HOME}/.bash_profile"
# source ~/.profile # get my PATH setup
export PATH=/usr/bin/python:$PATH
source ~/.bashrc  # get my Bash aliases
export RANGER_LOAD_DEFAULT_RC=False

test -e "${HOME}/.iterm2_shell_integration.bash" && source "${HOME}/.iterm2_shell_integration.bash"

