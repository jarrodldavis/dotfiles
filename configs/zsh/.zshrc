#!/usr/bin/env zsh

fpath=( ~/.dotfiles/configs/zshfuncs $fpath )
autoload -Uz docker-reset
autoload -Uz gibo-update

autoload -Uz compinit
compinit

# load configuration managed by system dependencies
if [ -f ~/.zshrc ]; then
    source ~/.zshrc
fi
