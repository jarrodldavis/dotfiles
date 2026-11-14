log_step 'Validating shell scripts...'

cd ~/.dotfiles

shopt -s globstar nullglob
posix_like=()
posix_like+=(modules/**/*.sh)

bash_like=()
bash_like+=(install.bash)
bash_like+=(modules/**/*.bash)

bash_like_helpers=()
bash_like_helpers+=(scripts/**/*.bash)
bash_like_helpers+=(modules/**/install/*.bash)
bash_like_helpers+=(modules/git/update-global-gitignore.bash)
bash_like_helpers+=(modules/homebrew/update-homebrew-bundle.bash)

declare -A excluded=()
for item in "${bash_like_helpers[@]}"; do
    excluded["$item"]=1
done
filtered=()
for item in "${bash_like[@]}"; do
    [[ -v 'excluded[$item]' ]] || filtered+=("$item")
done
bash_like=("${filtered[@]}")

fail=0

function check() {
    log_substep "Checking \`$file\` as \`$1\` script..."

    if shellcheck -x -a -s "$1" "$2" ; then
        echo 'Script passed validation.'
    else
        fail=$((fail+1))
    fi

    echo
}

function check_with_helpers() {
    check bash - <<EOF
#!/usr/bin/env bash
source scripts/helpers.bash
source $file
EOF
}

for file in "${posix_like[@]}"; do
    check sh "$file"
done

for file in "${bash_like[@]}"; do
    check bash "$file"
done

for file in "${bash_like_helpers[@]}"; do
    check_with_helpers "$file"
done

if (( fail == 0 )); then
    log_success 'All scripts passed validation!'
elif (( fail == 1 )); then
    log_error "1 script failed validation."
    exit 1
else
    log_error "$fail scripts failed validation."
    exit $fail
fi
