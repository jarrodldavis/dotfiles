#!/usr/bin/env bash

if [ -f "/home/linuxbrew/.linuxbrew/bin/brew" ]; then
    eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
fi

if [ -z "${EDITOR:-}" ]; then
    export EDITOR="vim"
fi
