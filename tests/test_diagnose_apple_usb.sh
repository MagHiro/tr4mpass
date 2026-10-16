#!/usr/bin/env bash
# Offline unit tests: no iPhone or USB connection required.
set -euo pipefail
root="$(cd "$(dirname "$0")/.." && pwd)"
work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT
cat > "$work/lsusb" <<'MOCK'
#!/usr/bin/env bash
printf '%s' "${MOCK_USB_OUTPUT:-}"
MOCK
chmod +x "$work/lsusb"

run_case() {
    local name="$1" data="$2" expected_status="$3" expected_text="$4"
    local status=0 output
    output=$(MOCK_USB_OUTPUT="$data" PATH="$work:$PATH" bash "$root/tools/diagnose-apple-usb.sh") || status=$?
    if [[ "$status" != "$expected_status" || "$output" != *"$expected_text"* ]]; then
        printf 'FAIL %s (exit=%d): %s\n' "$name" "$status" "$output" >&2
        exit 1
    fi
    printf 'PASS %s\n' "$name"
}

run_case dfu $'Bus 001 Device 002: ID 05ac:1227 Apple DFU\n' 1 'DFU, not Recovery'
run_case port-dfu $'Bus 001 Device 002: ID 05ac:f014 Apple Port DFU\n' 1 'DFU, not Recovery'
run_case recovery-1280 $'Bus 001 Device 003: ID 05ac:1280 Apple Recovery\n' 0 'Recovery Mode visible'
run_case recovery-1283 $'Bus 001 Device 003: ID 05ac:1283 Apple Recovery\n' 0 'Recovery Mode visible'
run_case normal $'Bus 001 Device 003: ID 05ac:12a8 Apple iPhone\n' 1 'other Apple USB mode'
run_case missing '' 1 'No Apple device visible'
run_case ambiguous $'Bus 001 Device 002: ID 05ac:1227 Apple DFU\nBus 001 Device 003: ID 05ac:1281 Apple Recovery\n' 1 'Multiple DFU/Recovery devices'
printf 'All diagnostic tests passed.\n'
