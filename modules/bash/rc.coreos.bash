function show_zincati_status() {
    [[ $- == *i* ]] || return 0

    local status
    status=$(systemctl show -P StatusText zincati.service 2>/dev/null) || return 0

    [[ -n "$status" ]] || return 0
    [[ "$status" == "periodically polling for updates"* ]] && return 0

    if [[ "$status" == *"failed attempts"* ]]; then
        printf '[zincati]\n\033[31m%s\033[39m\n' "$status"
    else
        printf '[zincati]\n\033[34m%s\033[39m\n' "$status"
    fi
}

show_zincati_status
unset -f show_zincati_status
