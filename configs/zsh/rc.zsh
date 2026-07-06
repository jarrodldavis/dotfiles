#!/usr/bin/env zsh

if [ -f "/home/linuxbrew/.linuxbrew/bin/brew" ]; then
    eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
fi

autoload -Uz compinit
compinit

unsetopt NOMATCH

if [ -z "${EDITOR:-}" ]; then
    export EDITOR="vim"
fi

if command -v gh >/dev/null 2>&1; then
    if gh extension list | grep -q 'gh cd'; then
        eval "$(gh extension exec cd init zsh --wrap-gh)"
    fi
fi
