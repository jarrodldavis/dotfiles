#!/bin/sh

if [ "$(uname)" = 'Darwin' ]; then
	exec pinentry-mac "$@"
fi
	exec pinentry-curses "$@"
fi
