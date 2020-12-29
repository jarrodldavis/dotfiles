#!/usr/bin/env bash

# Override any Visual Studio Code Development Container that forces Bash as the default shell.
if [ -f "/.dockerenv" ] && [ -z "$SKIP_FORCE_ZSH" ]; then
    eval $(/home/linuxbrew/.linuxbrew/bin/brew shellenv)
    exec env SHELL="$(command -v zsh)" zsh
fi
