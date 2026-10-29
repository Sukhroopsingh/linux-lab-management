# Linux Lab Management, Monitoring & Security System

**Mini project:** Linux Administration using Bash Shell Scripting  
**Purpose:** Combine Linux Experiments 1–6 into one menu-driven administration tool.

## Features

1. **System setup and package management:** checks kernel/distribution/boot information and provides guarded `dnf`/`yum` search, info, install, update, repository and removal operations.
2. **Storage and files:** creates a project workspace; demonstrates `pwd`, `mkdir`, `cd`, `touch`, `ls`, `echo`, `cat`, `cp`, `mv`, `rm`, `less`, `head`, `tail`, `nano`, and `vi`; provides optional swap and virtual-disk demos; offers partition practice against a disposable image file.
3. **Users, groups, permissions and ACL:** sets up `student1`, `student2`, `bca_group`, `/bca_shared`, and an ACL for `student2`.
4. **Marks report generator:** uses `grep`, regular expressions, `sed`, `cut`, `sort`, `uniq`, and pipelines to create report files.
5. **System troubleshooting:** uses `journalctl`, `dmesg`, `uptime`, and `free`; saves boot, error and troubleshooting reports.
6. **SELinux:** uses `sestatus`, `getenforce`, `setenforce`, `ls -Z`, `ls -Zd`, `tee`, and `restorecon` to demonstrate file context management.
7. **Complete report:** writes a combined system and student-data report.

## Requirements

- A Linux VM is recommended. Fedora, Rocky Linux or another RHEL-compatible system is best for the `dnf`/`yum` and SELinux parts.
- Bash, `journalctl`, and standard GNU utilities.
- Optional tools for their respective modules: `nano`, `vim`, `tree`, `wget`, `acl`, `fdisk`, `gdisk`, `losetup`, `mkfs.ext4`, `mount`, and SELinux tools.
- Administrative access (`sudo`) is needed for package changes, user/group changes, swap, loop devices, mounts and SELinux operations.

## Run the project

From the project directory:

```bash
chmod +x main.sh scripts/log_report.sh
./main.sh
```

Run as a regular user first. The project requests `sudo` only for the operations that need it. Do not start the whole application with `sudo` unless your instructor specifically requires it; it is better to keep files and reports owned by your normal account.

## Project structure

```text
linux-lab-management/
├── main.sh
├── lib/common.sh
├── modules/
│   ├── system_setup.sh
│   ├── storage_management.sh
│   ├── user_management.sh
│   ├── marks_report.sh
│   ├── troubleshooting.sh
│   └── selinux_security.sh
├── scripts/log_report.sh
├── data/students.txt
├── reports/
└── workspace/
```

## How to demonstrate each experiment

| Experiment | Project menu | Demonstration |
|---|---|---|
| 1. System setup and packages | `1` | Show kernel, distribution and boot logs; search/install tools (including optional `acl`); inspect repositories and package information. |
| 2. Files, storage, swap and editors | `2` | Create the workspace, copy/rename/view files, edit with nano/vi, demonstrate temporary swap, create a disposable filesystem image, or partition an image. |
| 3. Users, groups and ACL | `3` | Create test accounts and shared folder, check `id`/`groups`, inspect `chmod`/ownership and `getfacl`. |
| 4. Filters and regular expressions | `4` | Generate reports based on BCA, names, roll numbers, marks, sorting and duplicate counts. |
| 5. Logs and troubleshooting | `5` | Inspect boot, error, kernel and service logs; generate troubleshooting report files. |
| 6. SELinux contexts | `6` | Check status, inspect the sample web file, restore context and optionally test a temporary mode change. |

## Reports

Generated output is stored in `reports/`. The report generator creates files such as:

- `bca_students.txt`
- `updated_students.txt`
- `names_and_marks.txt`
- `sorted_by_name.txt`
- `duplicate_counts.txt`
- `student_name_counts.txt` and `repeated_student_names.txt` (the sample repeats the name Aman on different roll numbers)
- `boot_logs.txt`
- `error_logs.txt`
- `troubleshooting_report.txt`
- `final_lab_report.txt`

## Safety notes

- **Use a virtual machine dedicated to this lab.** Package updates and user/group changes can affect the OS.
- The system account module uses the names `student1`, `student2`, and `bca_group`, and the shared path `/bca_shared`. Check first that these are not used for something else.
- The swap module uses `/var/tmp/bca_linux_lab_swapfile`, asks for confirmation, then disables and removes the temporary swap file. If the VM or program is interrupted, check `swapon --show` and disable the lab swap with `sudo swapoff /var/tmp/bca_linux_lab_swapfile` before deleting it.
- The filesystem demo formats only `workspace/labdisk.img`, a project image file attached as a loop device.
- The partition demo opens `workspace/partition_lab.img` in `fdisk` or `gdisk`. **Never use a real disk device such as `/dev/sda` or `/dev/nvme0n1` for practice.** The script formats only the first partition detected on that generated image, after confirmation.
- The SELinux mode demo asks for confirmation and restores the original mode immediately after testing. Avoid permanently disabling SELinux.
- `userdel` does not recursively delete home directories. Review leftover test accounts and files manually.

## Important command examples

```bash
uname -r
systemctl get-default
cat /etc/os-release
dnf --version
dnf repolist
pwd
mkdir bca_linux_lab
touch intro.txt
cp intro.txt intro_backup.txt
mv notes.txt lab_notes.txt
grep -E 'BCA|BSc' data/students.txt
sed 's/BSc/BCA-General/' data/students.txt
cut -d ',' -f 2,4 data/students.txt
sort data/students.txt | uniq -c
journalctl -b
journalctl -p err
journalctl -k
sestatus
getenforce
ls -Z /var/www/html/index.html
sudo restorecon -v /var/www/html/index.html
```

## Notes for your viva

- **Bash** runs the menu, validates choices and connects each module.
- **Pipelines and redirection** let Linux commands filter data and save output to reports.
- **Permissions and ACLs** control access to shared files.
- **Loop devices** let a regular image file behave like a block device for safe storage practice.
- **SELinux** provides an additional mandatory access-control layer beyond normal Linux file permissions.
