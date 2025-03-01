#!/bin/zsh
set -euo pipefail

cd ~/.dotfiles

brew bundle dump --global --force

while IFS= read -r file; do
    cat "configs/brew/$file.Brewfile"
done < configs/brew/selected.txt | \
    grep -vFf - configs/brew/Brewfile || [[ $? -eq 1 ]] > configs/brew/Brewfile.new

mv configs/brew/Brewfile.new configs/brew/Brewfile

while IFS= read -r file; do
    cat "configs/brew/$file.Brewfile"
done < configs/brew/selected.txt | brew bundle install --cleanup --verbose --file=-
