#!/usr/bin/env zsh

# shellcheck disable=SC2206
fpath=( ~/.dotfiles/configs/zshfuncs $fpath )
autoload -Uz docker-reset
autoload -Uz gibo-update

autoload -Uz compinit
compinit

# lazy load copilot aliases since `gh copilot` is slow
function ghcs() {
    eval "$(gh copilot alias -- zsh)"
    ghcs $*
}

function ghce() {
    eval "$(gh copilot alias -- zsh)"
    ghce $*
}

# load configuration managed by system dependencies
if [ -f ~/.zshrc ]; then
    source ~/.zshrc
fi
