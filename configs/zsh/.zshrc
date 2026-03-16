#!/usr/bin/env zsh

if [ -f "/home/linuxbrew/.linuxbrew/bin/brew" ]; then
    eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
fi

autoload -Uz compinit
compinit

if [ -z "${EDITOR:-}" ]; then
    export EDITOR="vim"
fi

# load configuration managed by system dependencies
if [ -f ~/.zshrc ]; then
    source ~/.zshrc
fi
