#!/usr/bin/env bash

system_summary() {
    print_heading "Linux System Information"
    echo "Kernel version:"
    uname -r 2>&1 || true
    echo
    echo "Default boot target:"
    systemctl get-default 2>&1 || true
    echo
    echo "Linux distribution:"
    if [[ -r /etc/os-release ]]; then cat /etc/os-release; else echo "/etc/os-release not found."; fi
    echo
    echo "Current boot log sample (last 20 entries):"
    if have_command journalctl; then
        if [[ $EUID -eq 0 ]]; then journalctl -b -n 20 --no-pager 2>&1 || true;
        else journalctl -b -n 20 --no-pager 2>&1 || true; fi
    else echo "journalctl is not available."; fi
}

system_package_menu() {
    local pm choice package
    if ! pm="$(package_manager)"; then
        echo "This module expects Fedora/RHEL/Rocky/AlmaLinux (dnf or yum)."
        echo "Other distributions can still use the other project modules."
        pause; return
    fi
    while true; do
        print_heading "Package Management ($pm)"
        cat <<MENU
  1. Show package manager version
  2. List enabled repositories
  3. Search for a package
  4. Show package information
  5. Install lab tools (nano vim tree wget)
  6. Install a package by name (e.g. acl)
  7. Update installed packages
  8. Remove a package
  9. Back
MENU
        read -r -p "Choose [1-8]: " choice
        case "$choice" in
            1) "$pm" --version 2>&1 | head -n 8; pause ;;
            2) run_privileged "$pm" repolist; pause ;;
            3) read -r -p "Package/search term: " package; [[ -n "$package" ]] && "$pm" search "$package"; pause ;;
            4) read -r -p "Package name (e.g. nano): " package; [[ -n "$package" ]] && "$pm" info "$package"; pause ;;
            5)
                if confirm "Install nano, vim, tree and wget?"; then
                    run_privileged "$pm" install nano vim tree wget -y
                fi
                pause ;;
            6)
                read -r -p "Exact package name to install (e.g. acl): " package
                if [[ -n "$package" ]] && confirm "Install package '$package'?"; then
                    run_privileged "$pm" install "$package" -y
                fi
                pause ;;
            7)
                echo "System-wide package updates can change installed software."
                if confirm "Run $pm update now? Do this only in your lab VM"; then
                    run_privileged "$pm" update -y
                fi
                pause ;;
            8)
                read -r -p "Exact package name to remove (blank cancels): " package
                if [[ -n "$package" ]] && confirm "Remove package '$package'?"; then
                    run_privileged "$pm" remove "$package" -y
                fi
                pause ;;
            9) return ;;
            *) echo "Invalid choice."; pause ;;
        esac
    done
}

system_setup_menu() {
    local choice
    while true; do
        print_heading "System Information and Lab Setup"
        cat <<'MENU'
  1. Check system, kernel, boot target and boot logs
  2. Package manager operations (dnf/yum)
  3. Back
MENU
        read -r -p "Choose [1-3]: " choice
        case "$choice" in
            1) system_summary; pause ;;
            2) system_package_menu ;;
            3) return ;;
            *) echo "Invalid choice."; pause ;;
        esac
    done
}
