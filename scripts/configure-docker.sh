#!/usr/bin/env zsh
set -euo pipefail

config="${DOCKER_CONFIG:-$HOME/.docker}/config.json"
plugin_dir="$(brew --prefix)/lib/docker/cli-plugins"

mkdir -p "${config:h}"
[[ -f "$config" ]] || print '{}' > "$config"

json="$(jq --arg dir "$plugin_dir" '.cliPluginsExtraDirs = ((.cliPluginsExtraDirs // []) + [$dir] | unique)' "$config")"
echo "$json" > "$config"
