#!/bin/zsh
set -euo pipefail

cat ~/.dotfiles/configs/Brewfile | grep '^mas' | awk -F'id: ' '{print $2}' | xargs echo
