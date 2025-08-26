# Bioctl Linux

`bioctl-linux` is a command-line tool inspired by OpenBSD's `bioctl` utility, designed to manage RAID configurations and disk encryption on Linux systems. It provides functionality for monitoring RAID arrays, managing encrypted volumes, and adding RAID encryption key management. It supports both a Bash-based implementation `bioctl_linux.sh` and a newer C-based implementation `bioctl`.

## Features

-   **RAID Management**: Monitor RAID arrays, check status, and get alerts if a disk is missing or if the array is degraded.
-   **Disk Encryption**: Manage encrypted volumes using LUKS, including key management.
-   **Flexible RAID Levels**: Supports RAID 0, RAID 1, RAID 5, and RAID 6.
-   **Logging**: Tracks changes and errors in RAID and encryption setups with logging capabilities.

## Dependencies

Before using `bioctl-linux`, ensure the following packages are installed on your system:

-   `mdadm` (for RAID management)
-   `cryptsetup` (for disk encryption)
-   `gcc` (for compiling the C version)
-   `bash` (for running the script)

Install these using:

**On Debian-based distros:**
```bash
sudo apt update && sudo apt install mdadm cryptsetup gcc
```

**On RHEL-based distros:**
```bash
sudo dnf upgrade && sudo dnf install mdadm cryptsetup gcc
```

## Installation

**Clone the repository**:
```bash
git clone https://github.com/Umair-khurshid/bioctl-linux.git
cd bioctl-linux
```

**Bash Version (Quick Start)**
```bash
chmod +x bioctl_linux.sh
sudo ./bioctl_linux.sh status /dev/md0
```

**C Version (Recommended)**
Compile the C version:
```bash
gcc -o bioctl bioctl_linux.c
sudo ./bioctl status /dev/md0
```

## Usage

### Basic Commands

-   **Check RAID status**:
    ```bash
    sudo ./bioctl_linux.sh status /dev/md0
    sudo ./bioctl status /dev/md0
    ```

-   **Encrypt a new disk**:
    ```bash
    sudo ./bioctl_linux.sh encrypt /dev/sdX
    sudo ./bioctl encrypt /dev/sdX
    ```

-   **Open an encrypted disk**:
    ```bash
    sudo ./bioctl_linux.sh open /dev/sdX my_encrypted_disk
    sudo ./bioctl open /dev/sdX my_encrypted_disk
    ```

-   **Close an encrypted disk**:
    ```bash
    sudo ./bioctl_linux.sh close my_encrypted_disk
    sudo ./bioctl close my_encrypted_disk
    ```

-   **Add a new encryption key**:
    ```bash
    sudo ./bioctl_linux.sh key-management /dev/sdX add
    sudo ./bioctl key-management /dev/sdX add
    ```

-   **Remove an encryption key**:
    ```bash
    sudo ./bioctl_linux.sh key-management /dev/sdX remove
    sudo ./bioctl key-management /dev/sdX remove
    ```

### Example Usage

-   **Create a RAID 1 array**:
    ```bash
    sudo ./bioctl_linux.sh create /dev/md0 1 2 /dev/sda /dev/sdb
    sudo ./bioctl create /dev/md0 1 2 /dev/sda /dev/sdb
    ```

-   **Check if the RAID array is degraded**:
    ```bash
    sudo ./bioctl_linux.sh status /dev/md0
    sudo ./bioctl status /dev/md0
    ```

-   **Monitor RAID and encryption status with logging**:
    ```bash
    sudo ./bioctl_linux.sh --monitor
    ```

## Logging

By default, the script logs its actions and errors to `/var/log/bioctl_linux.log`. You can modify the log file location by editing the script.

## Error Handling

The script includes error handling for:

-   Missing disks in RAID arrays.
-   Degraded RAID status.
-   Issues during LUKS encryption key management.
-   Invalid or unsupported RAID levels.
