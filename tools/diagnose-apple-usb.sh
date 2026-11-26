#!/usr/bin/env bash
# Read-only Apple USB state diagnostic for Linux/WSL2.
# This script does not send DFU requests or modify the device.
set -u

printf 'Apple USB state diagnostic (read-only)\n'
if ! command -v lsusb >/dev/null 2>&1; then
    printf 'lsusb is missing; install usbutils.\n' >&2
    exit 2
fi
output="$(lsusb -d 05ac: 2>&1)"
status=$?
if ((status != 0)); then
    printf 'lsusb failed (exit %d): %s\n' "$status" "$output" >&2
    exit 2
fi
if [[ -z "$output" ]]; then
    printf 'No Apple device visible in Linux.\n'
    printf 'On WSL2, inspect usbipd list in Windows PowerShell.\n'
    exit 1
fi

printf '%s\n' "$output"
candidate_count=0
dfu_count=0
recovery_count=0
while IFS= read -r line; do
    if [[ $line =~ [Ii][Dd][[:space:]]+05[aA][cC]:([[:xdigit:]]{4}) ]]; then
        pid="${BASH_REMATCH[1],,}"
        case "$pid" in
            1227|f014) ((dfu_count+=1)); ((candidate_count+=1)); printf '0x%s: DFU, not Recovery\n' "$pid" ;;
            1280|1281|1282|1283) ((recovery_count+=1)); ((candidate_count+=1)); printf '0x%s: Recovery\n' "$pid" ;;
            *) printf '0x%s: other Apple USB mode\n' "$pid" ;;
        esac
    fi
done <<< "$output"

if ((candidate_count > 1)); then
    printf 'Multiple DFU/Recovery devices; disconnect other devices.\n'
    exit 1
elif ((recovery_count == 1)); then
    printf 'Recovery Mode visible to Linux.\n'
    exit 0
elif ((dfu_count == 1)); then
    printf 'Still in DFU; DFU_ABORT does not guarantee a Recovery transition.\n'
    exit 1
else
    printf 'No recognized DFU/Recovery device visible.\n'
    exit 1
fi
