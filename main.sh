#!/usr/bin/env bash
# Linux Lab Management, Monitoring & Security System
# Run on a Linux VM: chmod +x main.sh && ./main.sh
set -o pipefail

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
export ROOT_DIR
source "$ROOT_DIR/lib/common.sh"
source "$ROOT_DIR/modules/system_setup.sh"
source "$ROOT_DIR/modules/storage_management.sh"
source "$ROOT_DIR/modules/user_management.sh"
source "$ROOT_DIR/modules/marks_report.sh"
source "$ROOT_DIR/modules/troubleshooting.sh"
source "$ROOT_DIR/modules/selinux_security.sh"

mkdir -p "$DATA_DIR" "$REPORT_DIR" "$WORK_DIR" "$SCRIPT_DIR"

show_banner() {
    clear 2>/dev/null || true
    cat <<'BANNER'
============================================================
       LINUX LAB MANAGEMENT & SECURITY SYSTEM
============================================================
  Bash Shell Scripting Mini Project | Linux Administration
------------------------------------------------------------
BANNER
}

generate_complete_report() {
    local output="$REPORT_DIR/final_lab_report.txt"
    {
        echo "LINUX LAB MANAGEMENT & SECURITY SYSTEM"
        echo "======================================="
        echo "Generated on: $(date)"
        echo
        echo "[SYSTEM INFORMATION]"
        uname -a 2>&1 || true
        if [[ -r /etc/os-release ]]; then cat /etc/os-release; fi
        echo
        echo "[UPTIME AND MEMORY]"
        uptime 2>&1 || true
        free -h 2>&1 || true
        echo
        echo "[FILESYSTEM USAGE]"
        df -h 2>&1 || true
        echo
        echo "[PACKAGE MANAGER]"
        if command -v dnf >/dev/null 2>&1; then dnf --version 2>&1 | head -n 2;
        elif command -v yum >/dev/null 2>&1; then yum --version 2>&1 | head -n 2;
        else echo "Neither dnf nor yum was found."; fi
        echo
        echo "[SELINUX STATUS]"
        if command -v sestatus >/dev/null 2>&1; then
            if [[ $EUID -eq 0 ]]; then sestatus 2>&1 || true; else sudo sestatus 2>&1 || sestatus 2>&1 || true; fi
        elif command -v getenforce >/dev/null 2>&1; then getenforce 2>&1 || true
        else echo "SELinux tools are not installed on this system."; fi
        echo
        echo "[STUDENT DATA SUMMARY]"
        if [[ -f "$DATA_DIR/students.txt" ]]; then
            echo "Records (including header): $(wc -l < "$DATA_DIR/students.txt")"
            echo "BCA records: $(grep -c ',BCA,' "$DATA_DIR/students.txt" || true)"
            echo "Records ending in mark 85: $(grep -c '85$' "$DATA_DIR/students.txt" || true)"
        else echo "Student data file not found."; fi
        echo
        echo "[RECENT ERROR LOGS - LAST 10]"
        if command -v journalctl >/dev/null 2>&1; then
            if [[ $EUID -eq 0 ]]; then journalctl -p err -n 10 --no-pager 2>&1 || true;
            elif command -v sudo >/dev/null 2>&1; then sudo journalctl -p err -n 10 --no-pager 2>&1 || journalctl -p err -n 10 --no-pager 2>&1 || true;
            else journalctl -p err -n 10 --no-pager 2>&1 || true; fi
        else echo "journalctl is not available."; fi
        echo
        echo "Saved project reports are located in: $REPORT_DIR"
    } > "$output"
    echo "Complete lab report saved to: $output"
}

main_menu() {
    while true; do
        show_banner
        cat <<'MENU'
  1. System Information and Lab Setup
  2. Storage, Files, Editors and Swap Management
  3. Student Users, Groups, Permissions and ACL
  4. Student Marks Report Generator (grep/sed/cut/sort/uniq)
  5. System Troubleshooting and Log Reports
  6. Web Directory Security (SELinux)
  7. Generate Complete Lab Report
  8. Exit
MENU
        echo
        read -r -p "Enter your choice [1-8]: " choice
        case "$choice" in
            1) system_setup_menu ;;
            2) storage_management_menu ;;
            3) user_management_menu ;;
            4) marks_report_menu ;;
            5) troubleshooting_menu ;;
            6) selinux_security_menu ;;
            7) generate_complete_report; pause ;;
            8) echo "Thank you for using the Linux Lab Management System."; exit 0 ;;
            *) echo "Invalid choice. Select a number from 1 to 8."; pause ;;
        esac
    done
}

main_menu
