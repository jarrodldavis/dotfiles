#!/usr/bin/env bash
set -euo pipefail

install_dir="$HOME/.itch"
state_file="$install_dir/state.json"

[[ -f "$state_file" ]] || exit 0

versions="$(jq -r '
    [.ready, .current][]
    | select(type == "string" and length > 0)
' "$state_file")"

while IFS= read -r version; do
    [[ "$version" =~ ^[a-zA-Z0-9._+-]+$ ]] || continue

    images_dir="$install_dir/app-$version/resources/app/src/static/images"
    icon_source="$images_dir/logos/tray-monochrome.svg"
    icon_path="$images_dir/tray/itch.png"

    [[ -f "$icon_source" && -f "$icon_path" ]] || continue

    temp_icon="$(mktemp "$images_dir/tray/.itch-monochrome.XXXXXX.png")"

    if magick -background none "$icon_source" \
        -resize 256x256 \
        "$temp_icon"; then
        mv -f "$temp_icon" "$icon_path"
        printf 'Applied monochrome tray icon to itch %s\n' "$version"
    else
        rm -f "$temp_icon"
        exit 1
    fi
done <<< "$versions"
