#!/usr/bin/env bash
set -euo pipefail

# Require the same SDK-root variables configured for VS Code's Agent Host.
: "${VSCODE_AGENT_HOST_CODEX_SDK_ROOT:?Set VSCODE_AGENT_HOST_CODEX_SDK_ROOT to an absolute SDK root path}"
: "${VSCODE_AGENT_HOST_CLAUDE_SDK_ROOT:?Set VSCODE_AGENT_HOST_CLAUDE_SDK_ROOT to an absolute SDK root path}"
NODE_IMAGE="${NODE_IMAGE:-node:slim}"

[[ "$(uname -s)" == Linux ]] || { echo 'This updater targets Linux Agent Hosts' >&2; exit 1; }

# Lock is shared by manual and scheduled runs.
exec 9>"$HOME/.agent-sdk-update.lock"
flock -n 9 || { echo 'An SDK update is already running' >&2; exit 0; }

update_sdk() {
    local name="$1" package="$2" dest="$3" version="$4" entry="$5"
    local parent stage backup=""
    [[ "$dest" == /* && "$dest" != / ]] || { echo "SDK path must be absolute: $dest" >&2; return 1; }
    parent="$(dirname -- "$dest")"
    mkdir -p -- "$parent"
    parent="$(cd -- "$parent" && pwd -P)"
    dest="$parent/$(basename -- "$dest")"
    stage="$(mktemp -d "$parent/.$name-sdk.staging.XXXXXXXX")"

    echo "==> Updating $name SDK ($version) in $dest"
    if ! docker run --rm \
        --user "$(id -u):$(id -g)" \
        --env HOME=/tmp \
        --env npm_config_cache=/tmp/npm-cache \
        --env npm_config_update_notifier=false \
        --env npm_config_min_release_age=3 \
        --volume "$stage:/sdk:Z" \
        "$NODE_IMAGE" \
        npm install --prefix /sdk --no-save --no-package-lock --omit=peer \
            "${package}@${version}"; then
        rm -rf -- "$stage"
        echo "ERROR: Installation failed for $name; existing SDK preserved" >&2
        return 1
    fi

    if ! docker run --rm \
        --user "$(id -u):$(id -g)" \
        --env HOME=/tmp \
        --volume "$stage:/sdk:ro,Z" \
        "$NODE_IMAGE" node -e '
            const fs = require("fs");
            const [pkg, entry] = process.argv.slice(1);
            const root = `/sdk/node_modules/${pkg}`;
            const manifest = JSON.parse(fs.readFileSync(`${root}/package.json`, "utf8"));
            if (!fs.statSync(`${root}/${entry}`).isFile()) throw Error(`Missing ${entry}`);
            console.log(`${pkg} ${manifest.version}`);
        ' "$package" "$entry"; then
        rm -rf -- "$stage"
        echo "ERROR: Validation failed for $name; existing SDK preserved" >&2
        return 1
    fi

    if [[ -e "$dest" || -L "$dest" ]]; then
        backup="$dest.previous.$$"
        mv -- "$dest" "$backup"
    fi
    if ! mv -- "$stage" "$dest"; then
        [[ -z "$backup" ]] || mv -- "$backup" "$dest"
        rm -rf -- "$stage"
        return 1
    fi
    [[ -z "$backup" ]] || rm -rf -- "$backup"
    echo "Updated $name SDK: $dest"
}

echo "==> Pulling Docker image: $NODE_IMAGE"
docker pull "$NODE_IMAGE"

failed=0
update_sdk codex '@openai/codex' "$VSCODE_AGENT_HOST_CODEX_SDK_ROOT" "${CODEX_SDK_VERSION:-latest}" 'bin/codex.js' || failed=1
update_sdk claude '@anthropic-ai/claude-agent-sdk' "$VSCODE_AGENT_HOST_CLAUDE_SDK_ROOT" "${CLAUDE_SDK_VERSION:-latest}" 'sdk.mjs' || failed=1
exit "$failed"
