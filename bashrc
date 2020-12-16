#!/usr/bin/env bash

# Override any Visual Studio Code Development Container that forces Bash as the default shell.
if [ -f "/.dockerenv" ]; then
    export SHELL="$(command -v zsh)"                                                                                                                                                                                                                                   
    exec zsh
fi
