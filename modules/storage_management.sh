#!/usr/bin/env bash

storage_init_workspace() {
    mkdir -p "$WORK_DIR/bca_linux_lab" "$WORK_DIR/mount_test" "$REPORT_DIR"
    local lab="$WORK_DIR/bca_linux_lab"
    touch "$lab/intro.txt" "$lab/commands.txt" "$lab/notes.txt"
    if [[ ! -s "$lab/intro.txt" ]]; then echo "This is my Linux Administration Lab." > "$lab/intro.txt"; fi
    if [[ ! -s "$lab/notes.txt" ]]; then
        printf 'Line 1\nLine 2\nLine 3\nLine 4\nLine 5\n' > "$lab/notes.txt"
    fi
    echo "Workspace ready: $lab"
    echo "Current working directory (pwd):"
    (cd "$lab" && pwd)
    echo "Directory listing (ls -l):"
    ls -l "$lab"
}

file_command_demo() {
    local lab="$WORK_DIR/bca_linux_lab"
    storage_init_workspace
    print_heading "Copy, Rename, View and Remove Practice Files"
    (cd "$lab" && {
        echo 'Using cat:'; cat intro.txt
        cp intro.txt intro_backup.txt
        echo; echo 'After cp, listing files:'; ls -l
        mv notes.txt lab_notes.txt
        echo; echo 'After mv:'; ls -l
        echo; echo 'First two lines (head):'; head -n 2 lab_notes.txt
        echo; echo 'Last two lines (tail):'; tail -n 2 lab_notes.txt
        echo; echo 'Detailed directory listing (ls -l):'; ls -l
    })
    echo
    echo "The file '$lab/commands.txt' is a practice file."
    if confirm "Delete only this practice file using rm?"; then rm -f -- "$lab/commands.txt"; fi
    echo "For page-by-page viewing, run: less '$lab/lab_notes.txt'"
    echo "For editors, choose the nano/vi option in the menu."
}

editor_demo() {
    local editor="$1" lab="$WORK_DIR/bca_linux_lab" target
    storage_init_workspace
    if [[ "$editor" == vi ]]; then target="$lab/lab_notes.txt"; else target="$lab/intro.txt"; fi
    if ! have_command "$editor"; then echo "$editor is not installed. Install it from the System Setup menu."; return; fi
    "$editor" "$target"
}

swapfile_demo() {
    local swapfile="/var/tmp/bca_linux_lab_swapfile"
    if ! have_command fallocate || ! have_command mkswap || ! have_command swapon; then
        echo "Required swap tools (fallocate, mkswap, swapon) are not available."; return
    fi
    if [[ -e "$swapfile" ]]; then
        echo "A file already exists at $swapfile. It will not be overwritten."
        echo "If this project created and enabled it earlier, use the cleanup option shown in README.md."
        return
    fi
    echo "This creates a temporary 512 MB swap file at $swapfile and enables it."
    echo "Use only in a Linux lab VM; root permission is required."
    if ! confirm "Continue with swap-file demonstration?"; then return; fi
    require_privileges || return
    if ! run_privileged fallocate -l 512M "$swapfile"; then return; fi
    run_privileged chmod 600 "$swapfile" || { run_privileged rm -f -- "$swapfile"; return; }
    if ! run_privileged mkswap "$swapfile"; then run_privileged rm -f -- "$swapfile"; return; fi
    if ! run_privileged swapon "$swapfile"; then run_privileged rm -f -- "$swapfile"; return; fi
    echo; echo "Swap status (free -h):"; free -h
    echo; echo "Temporary swap has been enabled. It will now be disabled and removed."
    pause
    run_privileged swapoff "$swapfile" || { echo "Could not disable swap. The file was left in place at $swapfile."; return 1; }
    run_privileged rm -f -- "$swapfile"
    echo "Swap file disabled and removed."
}

loop_filesystem_demo() {
    local image_file="$WORK_DIR/labdisk.img" loopdev="" mountpoint="$WORK_DIR/mount_test"
    if ! have_command losetup || ! have_command mkfs.ext4 || ! have_command mount; then
        echo "Required commands (losetup, mkfs.ext4, mount) are not available."; return
    fi
    echo "A 500 MB image file will be created inside this project's workspace."
    echo "Only the image file will be formatted; no existing disk is selected."
    if ! confirm "Create and mount a disposable virtual disk image?"; then return; fi
    require_privileges || return
    if [[ -e "$image_file" ]]; then
        if confirm "Replace the existing project image $image_file? Its contents will be lost"; then
            rm -f -- "$image_file"
        else return; fi
    fi
    if ! fallocate -l 500M "$image_file"; then echo "Could not create disk image."; return; fi
    loopdev="$(run_privileged losetup --find --show "$image_file")" || { rm -f -- "$image_file"; return; }
    if [[ ! "$loopdev" =~ ^/dev/loop[0-9]+$ ]]; then
        echo "Unexpected loop device: $loopdev"; run_privileged losetup -d "$loopdev" || true; return
    fi
    echo "Attached image as $loopdev"
    if ! run_privileged mkfs.ext4 -F "$loopdev"; then
        run_privileged losetup -d "$loopdev" || true; return
    fi
    mkdir -p "$mountpoint"
    if ! run_privileged mount "$loopdev" "$mountpoint"; then
        run_privileged losetup -d "$loopdev" || true; return
    fi
    echo "Mounted filesystem; df -h output:"
    df -h "$mountpoint"
    echo "This file was created by the Linux Lab project." | run_privileged tee "$mountpoint/lab_test.txt" >/dev/null
    ls -l "$mountpoint"
    pause
    run_privileged umount "$mountpoint" || { echo "Unmount failed. Loop device remains attached as $loopdev."; return 1; }
    run_privileged losetup -d "$loopdev"
    echo "Virtual disk unmounted and detached. The image file remains at $image_file."
}

partition_image_demo() {
    local image_file="$WORK_DIR/partition_lab.img" tool loopdev="" partdev="" mountpoint="$WORK_DIR/partition_mount"
    if ! have_command fdisk && ! have_command gdisk; then echo "Install fdisk or gdisk first."; return; fi
    echo "SAFE PARTITION PRACTICE: this launches a partition editor against a 1 GB FILE in this project workspace."
    echo "Never choose a real device such as /dev/sda or /dev/nvme0n1 for this exercise."
    echo "In fdisk: use n to create one Linux partition, accept defaults, then w to write. Use q to quit without writing."
    echo "In gdisk: use n to create one partition, accept defaults, then w to write."
    if ! confirm "Create/edit the disposable partition image?"; then return; fi
    if [[ -e "$image_file" ]]; then
        if confirm "Replace existing partition image? Any partitions inside it will be lost"; then rm -f -- "$image_file"; else return; fi
    fi
    if ! fallocate -l 1G "$image_file"; then echo "Could not create image file."; return; fi
    echo "Choose editor: 1) fdisk  2) gdisk"
    read -r -p "Choice [1-2]: " tool
    case "$tool" in
        1) if ! have_command fdisk; then echo "fdisk is not installed."; return; fi; fdisk "$image_file" ;;
        2) if ! have_command gdisk; then echo "gdisk is not installed."; return; fi; gdisk "$image_file" ;;
        *) echo "Invalid choice."; return ;;
    esac
    echo; echo "Partition table check:"
    if have_command fdisk; then fdisk -l "$image_file" 2>&1 || true; fi
    require_privileges || return
    loopdev="$(run_privileged losetup --find --show --partscan "$image_file")" || return
    if have_command partprobe; then run_privileged partprobe "$loopdev" 2>/dev/null || true; fi
    if have_command udevadm; then run_privileged udevadm settle 2>/dev/null || true; fi
    echo "Loop device: $loopdev"
    lsblk "$loopdev" 2>&1 || true
    partdev="${loopdev}p1"
    if [[ ! -b "$partdev" ]]; then
        echo "No first partition device was detected. The image was not formatted."
        run_privileged losetup -d "$loopdev" || true
        echo "You can rerun this module and create a partition first. Image: $image_file"
        return
    fi
    echo "Detected partition $partdev. It will be formatted as ext4, erasing data in that partition image."
    if ! confirm "Format only $partdev?"; then run_privileged losetup -d "$loopdev" || true; return; fi
    if ! run_privileged mkfs.ext4 -F "$partdev"; then run_privileged losetup -d "$loopdev" || true; return; fi
    mkdir -p "$mountpoint"
    if ! run_privileged mount "$partdev" "$mountpoint"; then run_privileged losetup -d "$loopdev" || true; return; fi
    echo "Mounted partition; df -h output:"
    df -h "$mountpoint"
    echo "Partition lab test file" | run_privileged tee "$mountpoint/partition_test.txt" >/dev/null
    ls -l "$mountpoint"
    pause
    run_privileged umount "$mountpoint" || { echo "Unmount failed; loop device left attached: $loopdev"; return 1; }
    run_privileged losetup -d "$loopdev"
    echo "Partition image detached. Image remains at $image_file."
    echo "To repeat the exercise, use fdisk/gdisk on this image only; resizing is best practised by deleting and recreating a partition within this disposable file."
}

storage_management_menu() {
    local choice
    while true; do
        print_heading "Storage, Files, Editors and Swap Management"
        cat <<'MENU'
  1. Create/check the project workspace (pwd, mkdir, touch, ls)
  2. Demonstrate file commands (cat, cp, mv, rm, head, tail)
  3. Edit intro.txt with nano
  4. Edit lab_notes.txt with vi
  5. Temporary 512 MB swap-file demo (fallocate, mkswap, swapon, free, swapoff)
  6. Disposable disk-image filesystem demo (losetup, mkfs, mount, df, umount)
  7. Safe partition-image practice with fdisk/gdisk
  8. View workspace with less
  9. Back
MENU
        read -r -p "Choose [1-9]: " choice
        case "$choice" in
            1) storage_init_workspace; pause ;;
            2) file_command_demo; pause ;;
            3) editor_demo nano; pause ;;
            4) editor_demo vi; pause ;;
            5) swapfile_demo; pause ;;
            6) loop_filesystem_demo; pause ;;
            7) partition_image_demo; pause ;;
            8) storage_init_workspace; less "$WORK_DIR/bca_linux_lab/lab_notes.txt" 2>/dev/null || cat "$WORK_DIR/bca_linux_lab/lab_notes.txt"; pause ;;
            9) return ;;
            *) echo "Invalid choice."; pause ;;
        esac
    done
}
