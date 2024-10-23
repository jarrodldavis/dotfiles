#!/usr/bin/env zsh

if [ -f "/opt/homebrew/bin/brew" ]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
fi

# load configuration managed by system dependencies
if [ -f ~/.zprofile ]; then
    source ~/.zprofile
fi
