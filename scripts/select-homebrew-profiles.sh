#!/bin/zsh
set -euo pipefail

REINSTALL=0

while [ "$#" -gt 0 ]; do
    case "$1" in
        -r|--reinstall) REINSTALL=1 ;;
        *) echo "fatal: invalid option: $1"; exit 1 ;;
    esac
    shift
done

cd ~/.dotfiles

touch configs/brew/selected.txt

for brewfile in configs/brew/*.Brewfile; do
    profile=$(basename "$brewfile" .Brewfile)
    echo -n "Do you want to select the Homebrew profile '$profile'? (y/n): "
    read choice
    case "$choice" in
        y|Y)
            if ! grep -qx "$profile" configs/brew/selected.txt; then
                echo "$profile" >> configs/brew/selected.txt
            else
                echo "Profile '$profile' is already selected."
            fi
            ;;
        *)
            if grep -qx "$profile" configs/brew/selected.txt; then
                sed -i '' "/^$profile$/d" configs/brew/selected.txt
                echo "Profile '$profile' has been deselected."
            else
                echo "Skipping profile '$profile'"
            fi
            ;;
    esac
done

bundle_command="brew bundle install --verbose --file=-"
if [ "$REINSTALL" -eq 1 ]; then
    bundle_command="$bundle_command --force"
fi

while IFS= read -r file; do
    cat "configs/brew/$file.Brewfile"
done < configs/brew/selected.txt | eval $bundle_command
