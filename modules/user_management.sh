#!/usr/bin/env bash

user_management_setup() {
    local shared="/bca_shared"
    echo "This exercise creates system accounts student1/student2, group bca_group, and $shared."
    echo "Use a dedicated Linux virtual machine. If these names or folder already exist, their configuration may be affected."
    if ! confirm "Continue with user/group and shared-folder setup?"; then return; fi
    require_privileges || return
    if ! have_command useradd || ! have_command groupadd; then echo "useradd/groupadd commands are not available."; return; fi
    if ! have_command setfacl || ! have_command getfacl; then
        echo "ACL tools are missing. Install the acl package using the System Setup module first."
        return
    fi
    if ! getent group bca_group >/dev/null 2>&1; then run_privileged groupadd bca_group || return; else echo "Group bca_group already exists; reusing it."; fi
    for user in student1 student2; do
        if ! id "$user" >/dev/null 2>&1; then
            run_privileged useradd -m -s /bin/bash "$user" || return
            echo "Created account: $user"
        else echo "Account $user already exists; reusing it."; fi
    done
    echo "Set or confirm passwords for the two test users. You may cancel either password prompt."
    run_privileged passwd student1 || true
    run_privileged passwd student2 || true
    run_privileged usermod -aG bca_group student1 || return
    if [[ -e "$shared" ]] && ! confirm "$shared already exists. Continue and adjust its group/mode?"; then return; fi
    run_privileged mkdir -p "$shared" || return
    run_privileged chgrp bca_group "$shared" || return
    run_privileged chmod 770 "$shared" || return
    if [[ ! -e "$shared/notice.txt" ]]; then run_privileged touch "$shared/notice.txt" || return; fi
    run_privileged chown student1 "$shared/notice.txt" || return
    run_privileged chgrp bca_group "$shared/notice.txt" || return
    run_privileged chmod 660 "$shared/notice.txt" || return
    # Execute permission on the directory lets student2 traverse to the ACL-protected file.
    # Without this directory ACL, file-level read permission alone would not be enough.
    run_privileged setfacl -m u:student2:--x "$shared" || return
    run_privileged setfacl -m u:student2:r "$shared/notice.txt" || return
    echo
    echo "Shared directory permissions:"
    run_privileged ls -ld "$shared"
    run_privileged getfacl "$shared"
    run_privileged ls -l "$shared/notice.txt"
    echo
    echo "ACL details:"
    run_privileged getfacl "$shared/notice.txt"
    echo
    echo "student1 is a member of bca_group. student2 receives read access through an ACL."
}

user_management_inspect() {
    echo "User information:"
    id student1 2>&1 || true
    id student2 2>&1 || true
    echo
    echo "Group membership:"
    groups student1 2>&1 || true
    getent group bca_group 2>&1 || true
    echo
    echo "Shared directory permissions:"
    run_privileged ls -ld /bca_shared 2>&1 || true
    run_privileged ls -l /bca_shared/notice.txt 2>&1 || true
    echo
    echo "ACL:"
    if have_command getfacl; then run_privileged getfacl /bca_shared/notice.txt 2>&1 || true; else echo "getfacl not installed."; fi
}

user_management_acl_cleanup() {
    if [[ ! -e /bca_shared/notice.txt ]]; then echo "/bca_shared/notice.txt not found."; return; fi
    if ! confirm "Remove ACL entries from /bca_shared/notice.txt (setfacl -b)?"; then return; fi
    run_privileged setfacl -b /bca_shared/notice.txt
    if [[ -d /bca_shared ]]; then run_privileged setfacl -x u:student2 /bca_shared 2>/dev/null || true; fi
    echo "ACL entries removed from the notice file and (if present) directory."
    run_privileged getfacl /bca_shared/notice.txt 2>&1 || true
}

user_management_cleanup() {
    echo "Cleanup can remove the test accounts and group. It will not recursively delete home folders or other shared-folder content."
    if ! confirm "Remove student1/student2 accounts and bca_group if present?"; then return; fi
    require_privileges || return
    for user in student1 student2; do
        if id "$user" >/dev/null 2>&1; then run_privileged userdel "$user" || echo "Could not remove $user."; fi
    done
    if getent group bca_group >/dev/null 2>&1; then run_privileged groupdel bca_group || echo "Could not remove bca_group (it may still be in use)."; fi
    echo "Cleanup attempted. Review /bca_shared manually before removing any files."
}

user_management_menu() {
    local choice
    while true; do
        print_heading "Student Users, Groups, Permissions and ACL"
        cat <<'MENU'
  1. Create/prepare test users and shared folder
  2. Check users, groups, permissions and ACL
  3. Remove ACL entries (setfacl -b)
  4. Remove test users and group (careful)
  5. Back
MENU
        read -r -p "Choose [1-5]: " choice
        case "$choice" in
            1) user_management_setup; pause ;;
            2) user_management_inspect; pause ;;
            3) user_management_acl_cleanup; pause ;;
            4) user_management_cleanup; pause ;;
            5) return ;;
            *) echo "Invalid choice."; pause ;;
        esac
    done
}
