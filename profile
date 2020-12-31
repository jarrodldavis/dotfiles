#!/usr/bin/env sh

# Override Visual Studio Code default shell of `sh`.
if [ -f "/.dockerenv" ] && [ -z "$SKIP_FORCE_ZSH" ]; then
    eval $(/home/linuxbrew/.linuxbrew/bin/brew shellenv)
    exec env SHELL="$(command -v zsh)" zsh
fi
