marketplaces=(
    google/elephant-goldfish-model
    mattpocock/skills
)

plugins=(
    egm@egm
    mattpocock-skills@mattpocock
)

# shellcheck disable=SC2034
declare -A claude=(
    [name]="Claude"
    [config]="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"
    [settings]="settings.json"
    [instructions]="CLAUDE.md"
    [refresh-verb]="update"
    [plugin-verb]="install"
)

# shellcheck disable=SC2034
declare -A codex=(
    [name]="Codex"
    [config]="${CODEX_HOME:-$HOME/.codex}"
    [settings]=""
    [instructions]="AGENTS.md"
    [refresh-verb]="upgrade"
    [plugin-verb]="add"
)

# shellcheck disable=SC2034
declare -A copilot=(
    [name]="Copilot"
    [config]="${COPILOT_HOME:-$HOME/.copilot}"
    [settings]="settings.json"
    [instructions]="copilot-instructions.md"
    [refresh-verb]="update"
    [plugin-verb]="install"
)

agents=(claude codex copilot)

registered_marketplaces() {
    case "$1" in
        copilot) copilot plugin marketplace list --json | jq -r '.[].source | sub("^GitHub: "; "")' ;;
        *) ;;
    esac
}

configure_agent() {
    local agent="$1"
    local -n manifest="$agent"
    local name config instructions settings registered marketplace verb plugin

    name="${manifest[name]}"
    log_substep "Configuring $name..."

    if ! command -v "$agent" >/dev/null 2>&1; then
        log_warning "$name is not installed, skipping configuration"
        return
    fi

    config="${manifest[config]}"
    instructions="${manifest[instructions]}"
    symlink AGENTS.md "$config/$instructions"

    if [[ -n "${manifest[settings]}" ]]; then
        settings="${manifest[settings]}"
        symlink "$agent/$settings" "$config/$settings"
    fi

    registered=$(registered_marketplaces "$agent")
    for marketplace in "${marketplaces[@]}"; do
        # Workaround for https://github.com/github/copilot-cli/issues/4777
        if grep -Fxq -- "$marketplace" <<< "$registered"; then
            continue
        fi

        "$agent" plugin marketplace add "$marketplace"
    done

    verb="${manifest[refresh-verb]}"
    "$agent" plugin marketplace "$verb"

    verb="${manifest[plugin-verb]}"
    for plugin in "${plugins[@]}"; do
        "$agent" plugin "$verb" "$plugin"
    done
}

for agent in "${agents[@]}"; do
    configure_agent "$agent"
done
