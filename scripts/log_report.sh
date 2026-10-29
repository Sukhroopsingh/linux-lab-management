#!/usr/bin/env bash
# Creates a simple Linux troubleshooting report.
set -o pipefail
OUTPUT="${1:-troubleshooting_report.txt}"
mkdir -p "$(dirname -- "$OUTPUT")"

run_logs() {
    if [[ ${EUID:-$(id -u)} -eq 0 ]]; then journalctl "$@" --no-pager 2>&1
    elif command -v sudo >/dev/null 2>&1; then sudo journalctl "$@" --no-pager 2>&1 || journalctl "$@" --no-pager 2>&1
    else journalctl "$@" --no-pager 2>&1; fi
}

{
    echo "Simple Linux Troubleshooting Report"
    echo "===================================="
    echo
    echo "Date:"
    date
    echo
    echo "System Uptime:"
    uptime 2>&1 || true
    echo
    echo "Recent Error Logs (last 10):"
    run_logs -p err -n 10
    echo
    echo "Recent Kernel Logs (last 10):"
    run_logs -k -n 10
    echo
    echo "Filesystem Usage:"
    df -h 2>&1 || true
    echo
    echo "Memory and Swap:"
    free -h 2>&1 || true
} > "$OUTPUT"

echo "Report written to $OUTPUT"
