#!/usr/bin/env bash
set -euo pipefail

container="sseedit"
release_api="https://api.github.com/repos/TES5Edit/TES5Edit/releases/latest"

config_dir="${XDG_CONFIG_HOME:-$HOME/.config}/sseedit"
config_file="$config_dir/paths.conf"

default_install_dir="$HOME/.local/opt/SSEEdit"

steam_dir="$HOME/.local/share/Steam"
default_skyrim_root="$steam_dir/steamapps/common/Skyrim Special Edition"
default_skyrim_prefix="$steam_dir/steamapps/compatdata/489830/pfx"

configure=false

case "${1:-}" in
    "")
        ;;
    --configure)
        configure=true
        ;;
    *)
        printf 'Usage: %s [--configure]\n' "$0" >&2
        exit 2
        ;;
esac

error() {
    zenity --error \
        --title="SSEEdit" \
        --text="$1"
}

require_commands() {
    local command

    for command in zenity curl jq 7z distrobox; do
        if ! command -v "$command" >/dev/null 2>&1; then
            error "Required command not found: $command"
            exit 1
        fi
    done
}

select_directory() {
    local title="$1"
    local default="$2"

    # Zenity needs an existing initial directory.
    if [[ ! -d "$default" ]]; then
        default="$HOME"
    fi

    zenity --file-selection \
        --directory \
        --title="$title" \
        --filename="$default/"
}

load_config() {
    [[ -f "$config_file" ]] || return 1

    local -a paths

    mapfile -t paths < "$config_file"

    [[ ${#paths[@]} -eq 3 ]] || return 1

    install_dir="${paths[0]}"
    skyrim_root="${paths[1]}"
    skyrim_prefix="${paths[2]}"

    [[ -d "$install_dir" ]] || return 1
    [[ -d "$skyrim_root/Data" ]] || return 1
    [[ -d "$skyrim_prefix" ]] || return 1
}

save_config() {
    mkdir -p "$config_dir"

    local tmp_file
    tmp_file=$(mktemp "$config_dir/.paths.XXXXXX")

    printf '%s\n' \
        "$install_dir" \
        "$skyrim_root" \
        "$skyrim_prefix" > "$tmp_file"

    mv -f -- "$tmp_file" "$config_file"
}

validate_paths() {
    local skyrim_ini
    local skyrim_plugins

    if [[ ! -d "$install_dir" ]]; then
        error "SSEEdit installation directory does not exist:\n$install_dir"
        exit 1
    fi

    if [[ ! -d "$skyrim_root/Data" ]]; then
        error "Skyrim's Data directory was not found:\n$skyrim_root/Data"
        exit 1
    fi

    # Accept either the Steam compatdata directory or its pfx subdirectory.
    if [[ -d "$skyrim_prefix/pfx/drive_c" ]]; then
        skyrim_prefix="$skyrim_prefix/pfx"
    fi

    skyrim_ini="$skyrim_prefix/drive_c/users/steamuser/Documents/My Games/Skyrim Special Edition/Skyrim.ini"

    skyrim_plugins="$skyrim_prefix/drive_c/users/steamuser/AppData/Local/Skyrim Special Edition/Plugins.txt"

    if [[ ! -f "$skyrim_ini" ]]; then
        error "Skyrim.ini was not found:\n$skyrim_ini"
        exit 1
    fi

    if [[ ! -f "$skyrim_plugins" ]]; then
        error "Plugins.txt was not found:\n$skyrim_plugins"
        exit 1
    fi
}

configure_paths() {
    mkdir -p "$default_install_dir"

    install_dir=$(
        select_directory \
            "Select SSEEdit installation directory" \
            "${install_dir:-$default_install_dir}"
    ) || exit 0

    skyrim_root=$(
        select_directory \
            "Select Skyrim Special Edition installation" \
            "${skyrim_root:-$default_skyrim_root}"
    ) || exit 0

    skyrim_prefix=$(
        select_directory \
            "Select Skyrim Special Edition Proton prefix" \
            "${skyrim_prefix:-$default_skyrim_prefix}"
    ) || exit 0

    validate_paths
    save_config
}

find_xedit() {
    find "$install_dir" \
        -mindepth 1 \
        -maxdepth 3 \
        -name pfx -prune -o \
        -type f \
        -iname 'xTESEdit.exe' \
        -print -quit
}

download_archive() {
    local url="$1"
    local destination="$2"
    local total_size="$3"

    (
        local curl_pid
        local downloaded
        local percentage=0

        curl -fsSL \
            "$url" \
            -o "$destination" &

        curl_pid=$!

        # Stop downloading if the progress dialog closes unexpectedly.
        trap 'kill "$curl_pid" 2>/dev/null || true' EXIT

        printf '# Downloading SSEEdit...\n'
        printf '0\n'

        while kill -0 "$curl_pid" 2>/dev/null; do
            if [[ -f "$destination" ]]; then
                downloaded=$(stat -c '%s' "$destination")

                percentage=$((downloaded * 100 / total_size))

                if ((percentage > 99)); then
                    percentage=99
                fi

                printf '%s\n' "$percentage"
            fi

            sleep 0.3
        done

        if ! wait "$curl_pid"; then
            exit 1
        fi

        printf '100\n'
    ) | zenity --progress \
        --title="Installing SSEEdit" \
        --text="Downloading SSEEdit..." \
        --percentage=0 \
        --auto-close \
        --no-cancel
}

install_sseedit() {
    local release_json
    local asset
    local archive_url
    local archive_filename
    local archive_name
    local archive_size
    local archive_dir
    local tmp_dir
    local extracted_exe

    # Reuse an existing installation.
    sseedit_exe=$(find_xedit)

    if [[ -n "$sseedit_exe" ]]; then
        return 0
    fi

    if ! zenity --question \
        --title="Install SSEEdit" \
        --text="SSEEdit was not found in:\n$install_dir\n\nDownload the latest release?"; then
        exit 0
    fi

    # Retrieve the latest release information.
    release_json=$(curl -fsSL "$release_api") || {
        error "Failed to retrieve SSEEdit release information."
        exit 1
    }

    # Find the official xEdit 7z archive.
    asset=$(
        jq -c '
            [
                .assets[]
                | select(
                    (.name | ascii_downcase | startswith("xedit"))
                    and
                    (.name | ascii_downcase | endswith(".7z"))
                )
            ]
            | first // empty
        ' <<< "$release_json"
    )

    if [[ -z "$asset" ]]; then
        error "No xEdit 7z archive was found in the latest GitHub release."
        exit 1
    fi

    archive_url=$(jq -r '.browser_download_url' <<< "$asset")
    archive_filename=$(jq -r '.name' <<< "$asset")
    archive_size=$(jq -r '.size' <<< "$asset")

    if [[ ! "$archive_size" =~ ^[0-9]+$ ]] || ((archive_size == 0)); then
        error "GitHub returned an invalid archive size."
        exit 1
    fi

    archive_name="${archive_filename%.7z}"
    archive_dir="$install_dir/$archive_name"

    if [[ -e "$archive_dir" ]]; then
        error "The release directory already exists:\n$archive_dir"
        exit 1
    fi

    # Download and extract into a temporary directory.
    tmp_dir=$(mktemp -d "$install_dir/.sseedit-download.XXXXXX")
    trap 'rm -rf -- "$tmp_dir"' EXIT

    if ! download_archive \
        "$archive_url" \
        "$tmp_dir/$archive_filename" \
        "$archive_size"; then

        error "SSEEdit download failed."
        exit 1
    fi

    if ! 7z x -y \
        "-o$tmp_dir/extracted" \
        "$tmp_dir/$archive_filename"; then

        error "Failed to extract SSEEdit."
        exit 1
    fi

    # Verify the 32-bit TES executable.
    extracted_exe=$(
        find "$tmp_dir/extracted" \
            -type f \
            -iname 'xTESEdit.exe' \
            -print -quit
    )

    if [[ -z "$extracted_exe" ]]; then
        error "The archive does not contain xTESEdit.exe."
        exit 1
    fi

    # Install the extracted release.
    mv "$tmp_dir/extracted" "$archive_dir"

    sseedit_exe=$(find_xedit)

    if [[ -z "$sseedit_exe" ]]; then
        error "Could not locate xTESEdit.exe after installation."
        exit 1
    fi

    rm -rf -- "$tmp_dir"
    trap - EXIT
}

install_icon() {
    local icon_name="sseedit"
    local icon_root="$HOME/.local/share/icons/hicolor"

    local tmp_dir
    local ico_file
    local png_file
    local size
    local icon_dir

    # Reuse an existing icon.
    if find "$icon_root" \
        -path "*/apps/$icon_name.png" \
        -type f \
        -print -quit 2>/dev/null | grep -q .; then
        return 0
    fi

    # Verify the required tools are available inside Distrobox.
    if ! distrobox enter "$container" -- \
        bash -c 'command -v wrestool >/dev/null && command -v icotool >/dev/null'; then

        error "Icon extraction requires icoutils in the SSEEdit Distrobox."
        return 1
    fi

    tmp_dir=$(mktemp -d)
    mkdir -p "$tmp_dir/png"

    # Extract Windows icon resources from the executable.
    if ! distrobox enter "$container" -- \
        wrestool \
            --extract \
            --type=14 \
            "--output=$tmp_dir" \
            "$sseedit_exe"; then

        rm -rf -- "$tmp_dir"
        error "Failed to extract SSEEdit's icon."
        return 1
    fi

    ico_file=$(
        find "$tmp_dir" \
            -maxdepth 1 \
            -type f \
            -iname '*.ico' \
            -print -quit
    )

    if [[ -z "$ico_file" ]]; then
        rm -rf -- "$tmp_dir"
        error "No icon resources were found in xTESEdit.exe."
        return 1
    fi

    # Prefer the largest standard icon size available.
    for size in 256 128 64 48 32; do
        if distrobox enter "$container" -- \
            icotool \
                --extract \
                --width="$size" \
                --height="$size" \
                "--output=$tmp_dir/png" \
                "$ico_file"; then

            png_file=$(
                find "$tmp_dir/png" \
                    -type f \
                    -iname '*.png' \
                    -print -quit
            )

            if [[ -n "$png_file" ]]; then
                break
            fi
        fi
    done

    if [[ -z "${png_file:-}" ]]; then
        rm -rf -- "$tmp_dir"
        error "Failed to convert SSEEdit's icon to PNG."
        return 1
    fi

    # Install into the user's icon theme.
    icon_dir="$icon_root/${size}x${size}/apps"

    mkdir -p "$icon_dir"

    cp "$png_file" "$icon_dir/$icon_name.png"

    rm -rf -- "$tmp_dir"
}

initialize_wine() {
    local wine_prefix="$1"

    if [[ -d "$wine_prefix/drive_c" &&
        -f "$wine_prefix/system.reg" &&
        -f "$wine_prefix/user.reg" ]]; then
        return 0
    fi

    mkdir -p "$wine_prefix"

    (
        local wine_pid

        distrobox enter "$container" -- \
            env WINEPREFIX="$wine_prefix" \
            wineboot --init &

        wine_pid=$!

        trap 'kill "$wine_pid" 2>/dev/null || true' EXIT

        printf '# Initializing Wine prefix...\n'

        while kill -0 "$wine_pid" 2>/dev/null; do
            sleep 0.5
        done

        if ! wait "$wine_pid"; then
            exit 1
        fi

        printf '100\n'
    ) | zenity --progress \
        --title="Initializing Wine" \
        --text="Creating the SSEEdit Wine prefix..." \
        --pulsate \
        --auto-close \
        --no-cancel
}

winepath_to_windows() {
    local path="$1"

    distrobox enter "$container" -- \
        env WINEPREFIX="$wine_prefix" \
        winepath -w "$path"
}

launch_sseedit() {
    local skyrim_data
    local skyrim_ini
    local skyrim_plugins

    local windows_skyrim_data
    local windows_skyrim_ini
    local windows_skyrim_plugins

    skyrim_data="$skyrim_root/Data"

    skyrim_ini="$skyrim_prefix/drive_c/users/steamuser/Documents/My Games/Skyrim Special Edition/Skyrim.ini"

    skyrim_plugins="$skyrim_prefix/drive_c/users/steamuser/AppData/Local/Skyrim Special Edition/Plugins.txt"

    # Convert Linux paths to Windows paths understood by SSEEdit.
    windows_skyrim_data=$(winepath_to_windows "$skyrim_data")
    windows_skyrim_ini=$(winepath_to_windows "$skyrim_ini")
    windows_skyrim_plugins=$(winepath_to_windows "$skyrim_plugins")

    # Run the 32-bit executable in Skyrim Special Edition mode.
    exec distrobox enter "$container" -- \
        env WINEPREFIX="$wine_prefix" \
        wine "$sseedit_exe" \
            -SSE \
            "-D:$windows_skyrim_data" \
            "-I:$windows_skyrim_ini" \
            "-P:$windows_skyrim_plugins"
}

main() {
    require_commands

    # Prompt on first launch or when explicitly requested.
    if [[ "$configure" == true ]] || ! load_config; then
        configure_paths
    fi

    validate_paths

    # Install SSEEdit if it isn't already present.
    install_sseedit

    install_icon || true

    # Keep Wine's prefix inside the selected installation directory.
    wine_prefix="$install_dir/pfx"

    initialize_wine "$wine_prefix"

    launch_sseedit
}

main "$@"
