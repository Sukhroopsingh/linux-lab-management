#!/usr/bin/env bash

selinux_status() {
    print_heading "SELinux Status"
    if have_command sestatus; then run_privileged sestatus 2>&1 || sestatus 2>&1 || true; fi
    if have_command getenforce; then echo "Current mode:"; getenforce 2>&1 || true;
    else echo "SELinux tools are not available. This may not be a SELinux-enabled distribution."; fi
}

selinux_web_setup() {
    local webdir="/var/www/html" page="$webdir/index.html"
    echo "This creates or updates a sample page at $page."
    if ! have_command getenforce; then echo "SELinux commands are unavailable on this system."; return; fi
    if [[ -e "$page" ]] && ! confirm "$page already exists. Replace its contents with the lab page?"; then return; fi
    require_privileges || return
    run_privileged mkdir -p "$webdir" || return
    printf 'Welcome to BCA Linux Lab\n' | run_privileged tee "$page" >/dev/null || return
    echo "Normal file permissions:"
    run_privileged ls -l "$page" 2>&1 || true
    echo
    echo "SELinux context:"
    run_privileged ls -Z "$page" 2>&1 || true
    echo
    echo "Directory context:"
    run_privileged ls -Zd "$webdir" 2>&1 || true
    echo
    echo "Restoring default context:"
    run_privileged restorecon -v "$page" 2>&1 || true
    run_privileged ls -Z "$page" 2>&1 || true
}

selinux_restore_context() {
    local path
    path="$(safe_read_path "Path to restore (file or directory)" "/var/www/html")"
    if [[ ! -e "$path" ]]; then echo "Path does not exist: $path"; return; fi
    require_privileges || return
    run_privileged restorecon -Rv "$path"
    echo "Context after restorecon:"
    run_privileged ls -Zd "$path" 2>&1 || true
}

selinux_temporary_mode_demo() {
    local original
    if ! have_command getenforce || ! have_command setenforce; then
        echo "SELinux mode tools are unavailable."; return
    fi
    original="$(getenforce 2>/dev/null)"
    if [[ "$original" == "Disabled" || -z "$original" ]]; then
        echo "SELinux is disabled or its mode cannot be read. setenforce cannot enable it."; return
    fi
    echo "Current SELinux mode: $original"
    echo "This demo changes mode briefly, then immediately restores the original mode."
    echo "Do not use Permissive mode as a permanent security fix."
    if ! confirm "Temporarily change SELinux mode on this lab VM?"; then return; fi
    require_privileges || return
    if [[ "$original" == "Enforcing" ]]; then
        run_privileged setenforce 0 || return
        echo "Temporary mode: $(getenforce)"
        run_privileged setenforce 1 || { echo "WARNING: restore Enforcing mode manually with: sudo setenforce 1"; return 1; }
    else
        run_privileged setenforce 1 || return
        echo "Temporary mode: $(getenforce)"
        run_privileged setenforce 0 || { echo "WARNING: restore Permissive mode manually with: sudo setenforce 0"; return 1; }
    fi
    echo "Restored original mode: $(getenforce)"
}

selinux_security_menu() {
    local choice
    while true; do
        print_heading "Web Directory Security (SELinux)"
        cat <<'MENU'
  1. Check SELinux status (sestatus/getenforce)
  2. Create sample web page and inspect context
  3. Restore default context for a path (restorecon)
  4. Briefly test setenforce and restore the original mode
  5. Back
MENU
        read -r -p "Choose [1-5]: " choice
        case "$choice" in
            1) selinux_status; pause ;;
            2) selinux_web_setup; pause ;;
            3) selinux_restore_context; pause ;;
            4) selinux_temporary_mode_demo; pause ;;
            5) return ;;
            *) echo "Invalid choice."; pause ;;
        esac
    done
}
