#!/usr/bin/env bash
set -euo pipefail
# shellcheck source=scripts/helpers.bash
source ~/.dotfiles/scripts/helpers.bash

module_dir="$HOME/.dotfiles/modules/discord"

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
        log_substep "Recreating Distrobox container: Fedora $container_version -> $fedora_version..."
        distrobox rm -f discord
        create_discord=1
    fi
else
    log_substep "Creating Distrobox container..."
    create_discord=1
fi

if (( create_discord )); then
    # `set +x` in `--pre-init-hooks` is a workaround for the verbose logging
    # that results in `distrobox create` stalling during nvidia integration.
    # https://github.com/89luca89/distrobox/issues/1589#issuecomment-6460085750

    distrobox create \
        --yes \
        --pull \
        --name discord \
        --image "$discord_image" \
        --nvidia \
        --pre-init-hooks "set +x"
fi

log_substep "Starting Distrobox container..."
distrobox enter discord -- bash -lc 'true'

log_substep "Setting up Discord repository..."
distrobox enter discord -- bash "$module_dir/setup-repo.bash"

log_substep "Installing Discord in Distrobox..."
distrobox enter discord -- sudo dnf install -y --refresh discord

log_substep "Configuring autostart..."
distrobox enter discord -- distrobox-export --app /usr/share/applications/discord.desktop
symlink "$module_dir/discord-distrobox.bash" ~/.local/bin/discord-distrobox
copy "$module_dir/discord-discord.desktop" ~/.local/share/applications/discord-discord.desktop
copy "$module_dir/discord-minimized.desktop" ~/.config/autostart/discord-minimized.desktop
