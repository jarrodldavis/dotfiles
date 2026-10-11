#!/usr/bin/env bash
set -euo pipefail
# shellcheck source=scripts/helpers.bash
source ~/.dotfiles/scripts/helpers.bash

log_step 'Configuring Discord Distrobox...'

# shellcheck disable=SC1091
source /etc/os-release
fedora_version="$VERSION_ID"

discord_image="registry.fedoraproject.org/fedora:$fedora_version"
create_discord=0

if podman container exists discord; then
    container_version=$(
        # shellcheck disable=SC2016
        distrobox enter discord -- sh -c '
            . /etc/os-release
            printf "%s" "$VERSION_ID"
        '
    )

    if [[ "$container_version" != "$fedora_version" ]]; then
        log_substep "Recreating Discord Distrobox: Fedora $container_version -> $fedora_version..."

        distrobox rm -f discord
        create_discord=1
    fi
else
    create_discord=1
fi

if (( create_discord )); then
    distrobox create \
        --yes \
        --pull \
        --name discord \
        --image "$discord_image" \
        --nvidia
fi

# shellcheck disable=SC2016
distrobox enter discord -- bash -lc '
    if ! rpm -q terra-release >/dev/null 2>&1; then
        sudo dnf install -y --nogpgcheck \
            --repofrompath "terra,https://repos.fyralabs.com/terra\$releasever" \
            terra-release
    fi

    sudo dnf install -y discord
'

distrobox enter discord -- distrobox-export --app /usr/share/applications/discord.desktop

symlink discord/discord-distrobox.bash ~/.local/bin/discord-distrobox
copy discord/discord-discord.desktop ~/.local/share/applications/discord-discord.desktop
copy discord/discord-minimized.desktop ~/.config/autostart/discord-minimized.desktop
