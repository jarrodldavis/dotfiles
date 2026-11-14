#!/usr/bin/env bash

set -euo pipefail

get_hostname() {
    case "$OSTYPE" in
        darwin*)
            scutil --get ComputerName 2>/dev/null || hostname
            ;;
        linux*)
            local pretty
            pretty=$(hostnamectl --pretty 2>/dev/null) || pretty=

            if [[ -n "$pretty" ]]; then
                printf '%s\n' "$pretty"
            else
                hostname
            fi
            ;;
        *)
            echo "$HOSTNAME"
            ;;
    esac
}

op item get "$(get_hostname)" --fields label=password --reveal
