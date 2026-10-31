#!/bin/sh
set -eu

pci=/sys/bus/pci/devices/0000:01:00.0

# Lenovo OEM NVIDIA RTX 4070 Ti SUPER
[ "$(cat "$pci/vendor")" = "0x10de" ] || exit 0
[ "$(cat "$pci/device")" = "0x2705" ] || exit 0
[ "$(cat "$pci/subsystem_vendor")" = "0x17aa" ] || exit 0
[ "$(cat "$pci/subsystem_device")" = "0xe137" ] || exit 0

command -v i2ctransfer >/dev/null 2>&1 || {
    echo "i2ctransfer not found" >&2
    exit 1
}

bus=

for _ in $(seq 1 10); do
    for d in /sys/bus/i2c/devices/i2c-*; do
        [ -f "$d/name" ] || continue

        if [ "$(cat "$d/name")" = "NVIDIA i2c adapter 1 at 1:00.0" ]; then
            bus="${d##*-}"
            break 2
        fi
    done

    sleep 0.5
done

if [ -z "$bus" ]; then
    echo "NVIDIA I2C adapter 1 not available" >&2
    exit 1
fi

write() {
    reg="$1"
    shift

    i2ctransfer -y "$bus" "w$((1 + $#))@0x49" "$reg" "$@"
    sleep 0.01
}

# Block 15: logo mark
write 0x30 0xb0
write 0x50 0x00
write 0x1b 0x00 0xc8 0xff
write 0x31 0xb1
write 0x32 0xb2

# Block 16: remaining GPU lighting
write 0x30 0xb0
write 0x15 0x00
write 0x1b 0x00 0xc8 0xff
write 0x31 0xb1
write 0x32 0xb2
