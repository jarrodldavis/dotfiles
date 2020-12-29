#!/usr/bin/env sh

# ensure Homebrew-installed Zsh is used, if installed
eval $(/home/linuxbrew/.linuxbrew/bin/brew shellenv)
exec env SHELL="$(command -v zsh)" zsh
