#!/usr/bin/env zsh

if [ -f "/home/linuxbrew/.linuxbrew/bin/brew" ]; then
    eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
fi

autoload -Uz compinit
compinit

# lazy load copilot aliases since `gh copilot` is slow
function ghcs() {
    eval "$(gh copilot alias -- zsh)"
    ghcs "$@"
}

function ghce() {
    eval "$(gh copilot alias -- zsh)"
    ghce "$@"
}

# load configuration managed by system dependencies
if [ -f ~/.zshrc ]; then
    source ~/.zshrc
fi
