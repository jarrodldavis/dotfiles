#!/usr/bin/env bash
set -euo pipefail
# shellcheck source=scripts/helpers.bash
source ~/.dotfiles/scripts/helpers.bash

log_step 'Validating shell scripts...'

cd ~/.dotfiles

shopt -s globstar nullglob
posix_like=()
posix_like+=(configs/**/*.sh)
bash_like=()
bash_like+=(install.bash)
bash_like+=(scripts/**/*.bash)
bash_like+=(configs/**/*.bash)
bash_like+=(configs/**/*.zsh)
bash_like+=(configs/zshfuncs/*)

fail=0

function check() {
    log_substep "Checking \`$file\` as \`$1\` script..."

    if shellcheck -x -s "$1" "$2" ; then
        echo 'Script passed validation.'
    else
        fail=$((fail+1))
    fi

    echo
}

for file in "${posix_like[@]}"; do
    check sh "$file"
done

for file in "${bash_like[@]}"; do
    check bash "$file"
done

if [ $fail = 0 ]; then
    log_success 'All scripts passed validation!'
elif [ $fail = 1 ]; then
    log_error "1 script failed validation."
    exit 1
else
    log_error "$fail scripts failed validation."
    exit $fail
fi
