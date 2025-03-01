#!/bin/zsh
set -euo pipefail

cd ~/.dotfiles

brew bundle dump --global --force

while IFS= read -r file; do
    cat "configs/brew/$file.Brewfile"
done < configs/brew/selected.txt | \
    (grep -vFf - configs/brew/Brewfile.full || [[ $? -eq 1 ]]) > configs/brew/Brewfile.new

while IFS= read -r file; do
    cat "configs/brew/$file.Brewfile"
done < configs/brew/selected.txt | \
    (grep -vFf configs/brew/Brewfile.full - || [[ $? -eq 1 ]]) > configs/brew/Brewfile.old

brew bundle install --global --cleanup
