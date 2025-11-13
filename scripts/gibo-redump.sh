#!/usr/bin/env zsh
set -euo pipefail

sed -E -n 's|### https://raw.github.com/github/gitignore/[[:alnum:]]*/(Global/)?([[:alnum:]]*).gitignore|\2|gp' | xargs gibo dump
