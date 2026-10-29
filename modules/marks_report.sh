#!/usr/bin/env bash

marks_data_file() { echo "$DATA_DIR/students.txt"; }

ensure_marks_data() {
    local source_file="$DATA_DIR/students.txt"
    mkdir -p "$DATA_DIR" "$REPORT_DIR"
    if [[ ! -f "$source_file" ]]; then
        cat > "$source_file" <<'DATA'
101,Aman,BCA,85
102,Riya,BCA,78
103,Karan,BCA,91
104,Neha,BSc,67
105,Aman,BCA,85
106,Simran,BCA,88
107,Raj,BSc,45
DATA
    fi
}

marks_generate_reports() {
    local file out
    ensure_marks_data
    file="$(marks_data_file)"
    out="$REPORT_DIR"
    print_heading "Generating reports from $file"
    echo "Input data:"; cat "$file"

    grep 'BCA' "$file" > "$out/bca_students.txt" || true
    grep 'Aman' "$file" > "$out/aman_records.txt" || true
    grep -i 'aman' "$file" > "$out/aman_case_insensitive.txt" || true
    grep -n 'BCA' "$file" > "$out/bca_line_numbers.txt" || true
    grep -v 'BCA' "$file" > "$out/non_bca_students.txt" || true
    grep '^101' "$file" > "$out/roll_101.txt" || true
    grep '85$' "$file" > "$out/marks_85.txt" || true
    grep -E 'BCA|BSc' "$file" > "$out/bca_or_bsc.txt" || true
    grep -F 'Aman,BCA' "$file" > "$out/fixed_string_aman_bca.txt" || true
    sed 's/BSc/BCA-General/' "$file" > "$out/updated_students.txt"
    cut -d ',' -f 1 "$file" > "$out/roll_numbers.txt"
    cut -d ',' -f 2 "$file" > "$out/student_names.txt"
    cut -d ',' -f 2,4 "$file" > "$out/names_and_marks.txt"
    sort "$file" > "$out/sorted_records.txt"
    sort -t ',' -k 2,2 "$file" > "$out/sorted_by_name.txt"
    sort "$file" | uniq > "$out/unique_records.txt"
    sort "$file" | uniq -c > "$out/duplicate_counts.txt"
    # The sample data repeats a student name, but the roll numbers differ.
    # Count repeated names separately so the report also demonstrates useful duplicate detection.
    cut -d ',' -f 2 "$file" | sort | uniq -c > "$out/student_name_counts.txt"
    awk '$1 > 1 { print }' "$out/student_name_counts.txt" > "$out/repeated_student_names.txt"

    echo
    echo "Reports created in $out:"
    ls -lh "$out"/{bca_students.txt,aman_records.txt,aman_case_insensitive.txt,bca_line_numbers.txt,non_bca_students.txt,roll_101.txt,marks_85.txt,bca_or_bsc.txt,fixed_string_aman_bca.txt,updated_students.txt,roll_numbers.txt,student_names.txt,names_and_marks.txt,sorted_records.txt,sorted_by_name.txt,unique_records.txt,duplicate_counts.txt,student_name_counts.txt,repeated_student_names.txt} 2>/dev/null || true
    echo
    echo "Exact-line counts (sort | uniq -c):"
    cat "$out/duplicate_counts.txt"
    echo
    echo "Repeated student names (names differ from full-record duplicates):"
    cat "$out/repeated_student_names.txt"
}

marks_report_menu() {
    local choice file query report
    ensure_marks_data
    while true; do
        print_heading "Student Marks Report Generator"
        cat <<'MENU'
  1. View student data
  2. Generate all reports (grep, regular expressions, sed, cut, sort, uniq)
  3. Search data with grep
  4. Edit student data with nano
  5. Reset sample student data
  6. Back
MENU
        read -r -p "Choose [1-6]: " choice
        file="$(marks_data_file)"
        case "$choice" in
            1) cat "$file"; pause ;;
            2) marks_generate_reports; pause ;;
            3)
                read -r -p "Enter search text/pattern (e.g. BCA, Aman, ^101, 85$): " query
                if [[ -n "$query" ]]; then grep -n -- "$query" "$file" || echo "No matching records found."; fi
                pause ;;
            4)
                if have_command nano; then nano "$file"; else echo "nano is not installed."; fi
                pause ;;
            5)
                if confirm "Replace student data with the original 7 sample records?"; then
                    cat > "$file" <<'DATA'
101,Aman,BCA,85
102,Riya,BCA,78
103,Karan,BCA,91
104,Neha,BSc,67
105,Aman,BCA,85
106,Simran,BCA,88
107,Raj,BSc,45
DATA
                    echo "Sample data restored.";
                fi
                pause ;;
            6) return ;;
            *) echo "Invalid choice."; pause ;;
        esac
    done
}
