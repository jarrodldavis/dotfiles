#!/bin/bash

set -euo pipefail

if [[ "${DEBUG:-0}" = "1" ]]; then
    set -x
fi

echo '==> Installing Xcode Command Line Tools...'

# https://github.com/Homebrew/brew/blob/e986264a3e5f4cb14cbc98efbc3c0e09aa363b9f/package/scripts/preinstall

CLT_PLACEHOLDER="/tmp/.com.apple.dt.CommandLineTools.installondemand.in-progress"
touch "${CLT_PLACEHOLDER}"

CLT_PACKAGE=$(softwareupdate -l |
    grep -B 1 "Command Line Tools" |
    awk -F"*" '/^ *\*/ {print $2}' |
    sed -e 's/^ *Label: //' -e 's/^ *//' |
    sort -V |
    tail -n1)

softwareupdate -i "${CLT_PACKAGE}"

rm -f "${CLT_PLACEHOLDER}"

if ! [[ -f "/Library/Developer/CommandLineTools/usr/bin/git" ]]; then
    echo
    echo 'Failed to install Xcode Command Line Tools'
    exit 1
fi

if [[ "${DEBUG:-0}" = "1" ]]; then
    echo
    echo '==> Skipping clone of dotfiles repository'
else
    echo
    echo '==> Cloning dotfiles repository...'
    git clone --verbose https://github.com/jarrodldavis/dotfiles.git ~/.dotfiles
fi

echo
echo '==> Building dotfiles installer...'
cd ~/.dotfiles
swift build -c release

echo
echo '==> Running dotfiles installer...'
.build/release/DotFiles
