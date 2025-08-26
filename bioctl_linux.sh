#!/bin/bash

# bioctl.sh - RAID and Disk Management Script
# Author: Umair Khurshid
# Requirements: mdadm, cryptsetup

## ----------------------------------------------------------------------------------------- ##
## ----------------------------------------------------------------------------------------- ##

# Check for root privileges
if [ "$(id -u)" -ne 0 ]; then
    echo "You must be root to run this script."
    exit 1
fi

# Define log file
LOG_FILE="/var/log/bioctl_linux.log"

# Function to log messages
log_message() {
    local log_level="$1"
    local message="$2"
    echo "$(date '+%Y-%m-%d %H:%M:%S') [$log_level] $message" >> "$LOG_FILE"
}

# Function to handle errors
handle_error() {
    local message="$1"
    log_message "ERROR" "$message"
    echo "Error: $message"
    exit 1
}

# Show usage information
usage() {
    echo "Usage: $0 {create|add|remove|status|encrypt|open|close|repair|key-management} [options]"
    echo "Examples:"
    echo "  $0 create /dev/md0 1 2 /dev/sda /dev/sdb"
    echo "  $0 add /dev/md0 /dev/sdc"
    echo "  $0 remove /dev/md0 /dev/sdb"
    echo "  $0 status /dev/md0"
    echo "  $0 encrypt /dev/sda"
    echo "  $0 open /dev/sda encrypted_disk"
    echo "  $0 close encrypted_disk"
    echo "  $0 repair"
    echo "  $0 key-management /dev/sda add"
    exit 1
}

# Ensure at least one argument is provided
if [ -z "$1" ]; then
    usage
fi

# Check required commands
command -v mdadm >/dev/null || handle_error "mdadm command not found. Install it and retry."
command -v cryptsetup >/dev/null || handle_error "cryptsetup command not found. Install it and retry."

# Create a new RAID array
create_raid() {
    if [ $# -lt 4 ]; then
        handle_error "Missing arguments for create."
    fi
    local raid_device="$1"
    local raid_level="$2"
    local raid_disks="$3"
    shift 3
    local devices="$@"

    if [ -e "$raid_device" ]; then
        handle_error "RAID device $raid_device already exists!"
    fi

    echo "Creating RAID array..."
    log_message "INFO" "Creating RAID array $raid_device with level $raid_level and devices $devices"

    for device in $devices; do
        if [ ! -b "$device" ]; then
            handle_error "Device $device does not exist!"
        fi
    done

    mdadm --create "$raid_device" \
        --level="$raid_level" \
        --raid-devices="$raid_disks" \
        $devices
    if [ $? -ne 0 ]; then
        handle_error "Failed to create RAID array $raid_device."
    fi
    log_message "INFO" "RAID array $raid_device created successfully."
}

# Add a disk to the RAID array
add_disk() {
    if [ $# -lt 2 ]; then
        handle_error "Missing arguments for add."
    fi
    local raid_device="$1"
    local new_disk="$2"
    if [ ! -b "$new_disk" ]; then
        handle_error "Disk $new_disk does not exist!"
    fi

    echo "Adding disk to RAID array..."
    log_message "INFO" "Adding disk $new_disk to RAID array $raid_device"

    mdadm --add "$raid_device" "$new_disk"
    if [ $? -ne 0 ]; then
        handle_error "Failed to add disk $new_disk to RAID array $raid_device."
    fi
    log_message "INFO" "Disk $new_disk added to RAID array $raid_device successfully."
}

# Remove a disk from the RAID array
remove_disk() {
    if [ $# -lt 2 ]; then
        handle_error "Missing arguments for remove."
    fi
    local raid_device="$1"
    local disk_to_remove="$2"

    echo "Removing disk from RAID array..."
    log_message "INFO" "Removing disk $disk_to_remove from RAID array $raid_device"

    mdadm --remove "$raid_device" "$disk_to_remove"
    if [ $? -ne 0 ]; then
        handle_error "Failed to remove disk $disk_to_remove from RAID array $raid_device."
    fi
    log_message "INFO" "Disk $disk_to_remove removed from RAID array $raid_device successfully."
}

# Check the status of the RAID array
status_raid() {
    if [ $# -lt 1 ]; then
        handle_error "Missing RAID device for status."
    fi
    local raid_device="$1"

    echo "Checking RAID status..."
    log_message "INFO" "Checking status of RAID array $raid_device"

    mdadm --detail "$raid_device"
    if [ $? -ne 0 ]; then
        handle_error "Failed to check RAID status for $raid_device."
    fi
}

# Encrypt a disk using LUKS
encrypt_disk() {
    if [ $# -lt 1 ]; then
        handle_error "Missing disk for encryption."
    fi
    local disk="$1"

    if cryptsetup isLuks "$disk"; then
        handle_error "Disk $disk is already encrypted!"
    fi

    echo "Encrypting disk..."
    log_message "INFO" "Encrypting disk $disk with LUKS"

    cryptsetup luksFormat "$disk"
    if [ $? -ne 0 ]; then
        handle_error "Failed to encrypt disk $disk."
    fi
    log_message "INFO" "Disk $disk encrypted successfully."
}

# Open an encrypted disk
open_disk() {
    if [ $# -lt 2 ]; then
        handle_error "Missing arguments for open."
    fi
    local disk="$1"
    local disk_name="$2"

    echo "Opening encrypted disk..."
    log_message "INFO" "Opening encrypted disk $disk as $disk_name"

    cryptsetup luksOpen "$disk" "$disk_name"
    if [ $? -ne 0 ]; then
        handle_error "Failed to open encrypted disk $disk."
    fi
    log_message "INFO" "Disk $disk opened as $disk_name successfully."
}

# Close an encrypted disk
close_disk() {
    if [ $# -lt 1 ]; then
        handle_error "Missing encrypted disk name."
    fi
    local disk_name="$1"

    echo "Closing encrypted disk..."
    log_message "INFO" "Closing encrypted disk $disk_name"

    cryptsetup luksClose "$disk_name"
    if [ $? -ne 0 ]; then
        handle_error "Failed to close encrypted disk $disk_name."
    fi
    log_message "INFO" "Disk $disk_name closed successfully."
}

# Repair RAID array
repair_raid() {
    echo "Repairing RAID array..."
    log_message "INFO" "Repairing RAID array."

    mdadm --assemble --scan --force
    if [ $? -ne 0 ]; then
        handle_error "Failed to repair RAID array."
    fi
}

# Key Management for LUKS
key_management() {
    if [ $# -lt 2 ]; then
        handle_error "Missing arguments for key management."
    fi
    local disk="$1"
    local operation="$2"

    case "$operation" in
        add)
            cryptsetup luksAddKey "$disk"
            ;; 
        remove)
            cryptsetup luksRemoveKey "$disk"
            ;; 
        *)
            handle_error "Unknown key management operation: $operation"
            ;; 
    esac

    if [ $? -ne 0 ]; then
        handle_error "Failed to manage encryption key for disk $disk."
    fi
    log_message "INFO" "Encryption key for disk $disk managed successfully."
}

# Main function to parse arguments
case "$1" in
    create)
        create_raid "$2" "$3" "$4" "${@:5}"
        ;; 
    add)
        add_disk "$2" "$3"
        ;; 
    remove)
        remove_disk "$2" "$3"
        ;; 
    status)
        status_raid "$2"
        ;; 
    encrypt)
        encrypt_disk "$2"
        ;; 
    open)
        open_disk "$2" "$3"
        ;; 
    close)
        close_disk "$2"
        ;; 
    repair)
        repair_raid
        ;; 
    key-management)
        key_management "$2" "$3"
        ;; 
    *)
        usage
        ;; 
esac
