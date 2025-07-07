#!/bin/zsh
set -euo pipefail

grep '^mas' ~/.dotfiles/configs/Brewfile-macos | awk -F'id: ' '{print $2}' | xargs echo
