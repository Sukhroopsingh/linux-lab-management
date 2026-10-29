#!/usr/bin/env bash

log_report_generate() {
    local output="$REPORT_DIR/troubleshooting_report.txt"
    mkdir -p "$REPORT_DIR"
    if [[ ! -x "$SCRIPT_DIR/log_report.sh" ]]; then chmod +x "$SCRIPT_DIR/log_report.sh" 2>/dev/null || true; fi
    "$SCRIPT_DIR/log_report.sh" "$output"
    echo "Troubleshooting report saved to: $output"
    [[ -f "$output" ]] && tail -n 35 "$output"
}

show_service_logs() {
    local service
    read -r -p "Service name [sshd, ssh, NetworkManager]: " service
    service="${service:-sshd}"
    if ! have_command journalctl; then echo "journalctl is unavailable."; return; fi
    echo "Showing recent logs for $service (press q to exit if pager opens)."
    if [[ $EUID -eq 0 ]]; then journalctl -u "$service" -n 80 --no-pager 2>&1 || true;
    else journalctl -u "$service" -n 80 --no-pager 2>&1 || run_privileged journalctl -u "$service" -n 80 --no-pager 2>&1 || true; fi
}

troubleshooting_menu() {
    local choice
    while true; do
        print_heading "System Troubleshooting and Log Reports"
        cat <<'MENU'
  1. View current boot logs (journalctl -b)
  2. View last 20 log entries (journalctl -n 20)
  3. View recent error logs (journalctl -p err)
  4. View kernel logs (dmesg / journalctl -k)
  5. View service logs (sshd, ssh, NetworkManager, etc.)
  6. Follow logs live (journalctl -f; Ctrl+C to stop)
  7. Save boot and error logs to report files
  8. Generate troubleshooting_report.txt using the report script
  9. View saved troubleshooting report
 10. Back
MENU
        read -r -p "Choose [1-10]: " choice
        case "$choice" in
            1) journalctl -b -n 100 --no-pager 2>&1 || run_privileged journalctl -b -n 100 --no-pager; pause ;;
            2) journalctl -n 20 --no-pager 2>&1 || run_privileged journalctl -n 20 --no-pager; pause ;;
            3) journalctl -p err -n 100 --no-pager 2>&1 || run_privileged journalctl -p err -n 100 --no-pager; pause ;;
            4) if have_command dmesg; then dmesg 2>&1 | tail -n 80; else run_privileged journalctl -k -n 80 --no-pager 2>&1; fi; pause ;;
            5) show_service_logs; pause ;;
            6) echo "Press Ctrl+C to stop following logs."; journalctl -f 2>&1 || run_privileged journalctl -f; pause ;;
            7)
                mkdir -p "$REPORT_DIR"
                if have_command journalctl; then
                    (journalctl -b --no-pager 2>&1 || run_privileged journalctl -b --no-pager 2>&1) > "$REPORT_DIR/boot_logs.txt"
                    (journalctl -p err --no-pager 2>&1 || run_privileged journalctl -p err --no-pager 2>&1) > "$REPORT_DIR/error_logs.txt"
                    echo "Saved $REPORT_DIR/boot_logs.txt and $REPORT_DIR/error_logs.txt"
                else echo "journalctl is unavailable."; fi
                pause ;;
            8) log_report_generate; pause ;;
            9) if [[ -f "$REPORT_DIR/troubleshooting_report.txt" ]]; then less "$REPORT_DIR/troubleshooting_report.txt"; else echo "Report not generated yet."; fi; pause ;;
            10) return ;;
            *) echo "Invalid choice."; pause ;;
        esac
    done
}
