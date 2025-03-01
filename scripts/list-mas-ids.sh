#!/bin/zsh
set -euo pipefail

for brewfile in ~/.dotfiles/configs/brew/*.Brewfile; do
    (grep '^mas' "$brewfile" || [[ $? -eq 1 ]]) | awk -F'id: ' '{print $2}' | xargs echo -n
done

echo
