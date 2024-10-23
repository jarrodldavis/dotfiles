#!/bin/zsh
set -euo pipefail

LOG_TEMPLATE='\033[1;%sm%b\033[0m\033[1;%sm%s\033[0m\n'

cd ~/.dotfiles

export SHELLCHECK_OPTS="-e SC2059 -e SC1090"

posix_like=()
posix_like+=(install.sh)

bash_like=()
bash_like+=(configs/zsh/{.zprofile,.zshrc})
bash_like+=(configs/zshfuncs/*)
bash_like+=(configs/zshenv)
bash_like+=(scripts/*)

fail=0

function check() {
    printf "$LOG_TEMPLATE" 35 '==> ' 39 "Checking \`$file\` as \`$1\` script..."

    if shellcheck -s "$1" "$2" ; then
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
    printf "$LOG_TEMPLATE" 32 '==> ' 39 'All scripts passed validation!'
elif [ $fail = 1 ]; then
    printf "$LOG_TEMPLATE" 31 '==> ' 39 "1 script failed validation."
    exit 1
else
    printf "$LOG_TEMPLATE" 31 '==> ' 39 "$fail scripts failed validation."
    exit $fail
fi
