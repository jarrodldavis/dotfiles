#!/usr/bin/env bash

exec /usr/bin/distrobox-enter -n discord -- \
    /bin/sh -c 'exec /usr/bin/discord "$@" >/dev/null 2>&1' \
    sh "$@"
