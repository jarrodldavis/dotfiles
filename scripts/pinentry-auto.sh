#!/bin/sh

if [ "$(uname)" = 'Darwin' ]; then
	exec pinentry-mac "$@"
else
	exec pinentry-curses "$@"
fi
