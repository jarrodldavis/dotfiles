#!/bin/sh

# Based on:
# https://kevinlocke.name/bits/2019/07/31/prefer-terminal-for-gpg-pinentry
# https://gist.github.com/kevinoid/189a0168ef4ceae76ed669cd696eaa37

set -Ceu

# Use pinentry-curses if $PINENTRY_USER_DATA contains USE_CURSES=1
case "${PINENTRY_USER_DATA-}" in
*USE_CURSES=1*)
	exec pinentry-curses "$@"
	;;
esac

# Otherwise, use macOS UI
exec pinentry-mac "$@"
