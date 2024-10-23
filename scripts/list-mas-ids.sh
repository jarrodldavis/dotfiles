#!/bin/zsh
set -euo pipefail

grep '^mas' ~/.dotfiles/configs/Brewfile | awk -F'id: ' '{print $2}' | xargs echo
