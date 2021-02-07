#!/bin/sh

# Override development containers that default to `/bin/sh` or `/bin/bash`.

case "$-" in
    *i*) interactive=1 ;;
      *) interactive=0 ;;
esac

if [ -t 0 ] && [ "$interactive" = '1' ] && [ -f "/.dockerenv" ] && [ -z "$SKIP_FORCE_ZSH" ]; then
    eval $(/home/linuxbrew/.linuxbrew/bin/brew shellenv)
    exec env SHELL="$(command -v zsh)" zsh -l
fi
