#!/usr/bin/env bash
# Shared helpers used by all project modules.
DATA_DIR="$ROOT_DIR/data"
REPORT_DIR="$ROOT_DIR/reports"
WORK_DIR="$ROOT_DIR/workspace"
SCRIPT_DIR="$ROOT_DIR/scripts"

pause() {
    echo
    read -r -p "Press Enter to continue..." _ || true
}

confirm() {
    local prompt="${1:-Are you sure?}"
    local answer
    read -r -p "$prompt [y/N]: " answer
    [[ "$answer" =~ ^([yY]|[yY][eE][sS])$ ]]
}

have_command() { command -v "$1" >/dev/null 2>&1; }

run_privileged() {
    if [[ ${EUID:-$(id -u)} -eq 0 ]]; then
        "$@"
    elif have_command sudo; then
        sudo "$@"
    else
        echo "This operation needs root privileges. Run the project with sudo or install sudo." >&2
        return 1
    fi
}

require_privileges() {
    if [[ ${EUID:-$(id -u)} -eq 0 ]]; then return 0; fi
    if ! have_command sudo; then
        echo "This action needs root privileges, but sudo is not available." >&2
        return 1
    fi
    sudo -v || return 1
}

safe_read_path() {
    local label="$1" default_value="$2" result
    read -r -p "$label [$default_value]: " result
    printf '%s' "${result:-$default_value}"
}

print_heading() {
    printf '\n--- %s ---\n' "$1"
}

is_rhel_package_manager() {
    have_command dnf || have_command yum
}

package_manager() {
    if have_command dnf; then echo dnf
    elif have_command yum; then echo yum
    else return 1; fi
}
