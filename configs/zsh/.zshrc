#!/usr/bin/env zsh

if [ -f "/opt/homebrew/bin/brew" ]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
fi

fpath=( ~/.dotfiles/configs/zshfuncs $fpath )
autoload -Uz docker-reset
autoload -Uz gibo-update

# load configuration managed by system dependencies
if [ -f ~/.zshrc ]; then
    source ~/.zshrc
fi
