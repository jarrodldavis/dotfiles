#!/usr/bin/env bash
set -euo pipefail

NODE_IMAGE="${NODE_IMAGE:-node:slim}"

[[ "$(uname -s)" == Linux ]] || { echo 'This updater targets Linux Agent Hosts' >&2; exit 1; }

exec 9>"$HOME/.agent-sdk-update.lock"
flock -n 9 || { echo 'An SDK update is already running' >&2; exit 0; }

dest="$HOME/.vscode-agent-sdks"

echo "==> Pulling Docker image: $NODE_IMAGE"
docker pull "$NODE_IMAGE"

echo "==> Installing SDKs to $dest"
mkdir -p -- "$dest"
docker run --rm \
    --user "$(id -u):$(id -g)" \
    --env HOME=/tmp \
    --volume "$dest:/sdk:Z" \
    "$NODE_IMAGE" \
    npm install \
        --prefix /sdk \
        --cache /tmp/npm-cache \
        --no-update-notifier \
        --min-release-age=3 \
        --no-save \
        --no-package-lock \
        --omit=peer \
        --verbose \
        --no-progress \
        --no-color \
        "@openai/codex@${CODEX_SDK_VERSION:-latest}" \
        "@anthropic-ai/claude-agent-sdk@${CLAUDE_SDK_VERSION:-latest}"
