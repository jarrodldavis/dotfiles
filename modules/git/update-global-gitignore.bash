log_step 'Updating global gitignore...'

if ! command -v gibo >/dev/null 2>&1; then
    log_warning "gibo is not installed. Please install gibo to update the global gitignore."
    exit 0
fi

if ! gibo update; then
    log_warning "gibo update failed, checking for corruption..."
    gibo_root="$(gibo root)"
    if [[ -d "$gibo_root/.git" && ! -L "$gibo_root" ]] && ! git -C "$gibo_root" fsck --full; then
        log_warning "gibo root is corrupted, removing it and retrying the update..."
        rm -rfv -- "$gibo_root"
        gibo update
    else
        log_fatal 'gibo root was not confirmed corrupt, exiting for manual investigation.'
    fi
fi

GITIGNORE_FILE="$module_dir/gitignore"
GITIGNORE_CONTENTS="$(cat "$GITIGNORE_FILE")"
echo "$GITIGNORE_CONTENTS" | \
    sed -E -n 's|### https://raw.github.com/github/gitignore/[[:alnum:]]*/(Global/)?([[:alnum:]]*).gitignore|\2|gp' | \
    xargs gibo dump > "$GITIGNORE_FILE"
