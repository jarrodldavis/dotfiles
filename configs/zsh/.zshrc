#!/usr/bin/env zsh

fpath=( ~/.dotfiles/configs/zshfuncs $fpath )
autoload -Uz docker-reset
autoload -Uz gibo-update

# load configuration managed by system dependencies
if [ -f ~/.zshrc ]; then
    source ~/.zshrc
fi
