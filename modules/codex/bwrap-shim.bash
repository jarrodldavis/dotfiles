#!/usr/bin/env bash
set -euo pipefail

# Remove the `--proc /proc` arguments for compatibility with Codex inside Docker containers.
# Based on this workaround: https://github.com/openai/codex/issues/44329#issuecomment-5704259126

rewritten=()
while (( $# )); do
    if [[ "$1" == --proc && "${2-}" == /proc ]]; then
        shift 2
    else
        rewritten+=("$1")
        shift
    fi
done

exec "REPLACE_WITH_BREW_PREFIX/bin/bwrap" "${rewritten[@]}"
