#!/bin/bash

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

# Show usage information
usage() {
    echo "Usage: $0 {create|add|remove|status|encrypt|decrypt|repair|key-management} [options]"
    echo "Examples:"
    echo "  $0 create /dev/md0 1 2 /dev/sda /dev/sdb"
    echo "  $0 add /dev/md0 /dev/sdc"
    echo "  $0 remove /dev/md0 /dev/sdb"
    echo "  $0 status /dev/md0"
    echo "  $0 encrypt /dev/sda"
    echo "  $0 decrypt encrypted_disk"
    echo "  $0 repair"
    echo "  $0 key-management /dev/sda add"
    exit 1
}

# Ensure at least one argument is provided
if [ -z "$1" ]; then
    echo "Error: No arguments provided."
    usage
fi

# Create a new RAID array
create_raid() {
    if [ $# -lt 4 ]; then
        echo "Error: Missing arguments for create."
        usage
    fi
    local raid_device="$1"
    local raid_level="$2"
    local raid_disks="$3"
    shift 3
    local devices="$@"

    echo "Creating RAID array..."
    log_message "INFO" "Creating RAID array $raid_device with level $raid_level and devices $devices"

    # Check if devices exist
    for device in $devices; do
        if [ ! -b "$device" ]; then
            log_message "ERROR" "Device $device does not exist!"
            echo "Error: Device $device does not exist!"
            exit 1
        fi
    done

    # Create the RAID array
    mdadm --create "$raid_device" --level="$raid_level" --raid-devices="$raid_disks" $devices
    if [ $? -eq 0 ]; then
        log_message "INFO" "RAID array $raid_device created successfully."
    else
        log_message "ERROR" "Failed to create RAID array $raid_device."
        exit 1
    fi
}

# Add a disk to the RAID array
add_disk() {
    if [ $# -lt 2 ]; then
        echo "Error: Missing arguments for add."
        usage
    fi
    local raid_device="$1"
    local new_disk="$2"
    
    echo "Adding disk to RAID array..."
    log_message "INFO" "Adding disk $new_disk to RAID array $raid_device"

    mdadm --add "$raid_device" "$new_disk"
    if [ $? -eq 0 ]; then
        log_message "INFO" "Disk $new_disk added to RAID array $raid_device successfully."
    else
        log_message "ERROR" "Failed to add disk $new_disk to RAID array $raid_device."
        exit 1
    fi
}

# Remove a disk from the RAID array
remove_disk() {
    if [ $# -lt 2 ]; then
        echo "Error: Missing arguments for remove."
        usage
    fi
    local raid_device="$1"
    local disk_to_remove="$2"

    echo "Removing disk from RAID array..."
    log_message "INFO" "Removing disk $disk_to_remove from RAID array $raid_device"

    mdadm --remove "$raid_device" "$disk_to_remove"
    if [ $? -eq 0 ]; then
        log_message "INFO" "Disk $disk_to_remove removed from RAID array $raid_device successfully."
    else
        log_message "ERROR" "Failed to remove disk $disk_to_remove from RAID array $raid_device."
        exit 1
    fi
}

# Check the status of the RAID array
status_raid() {
    if [ $# -lt 1 ]; then
        echo "Error: Missing RAID device for status."
        usage
    fi
    local raid_device="$1"

    echo "Checking RAID status..."
    log_message "INFO" "Checking status of RAID array $raid_device"

    mdadm --detail "$raid_device"
    if [ $? -eq 0 ]; then
        log_message "INFO" "RAID array $raid_device status checked successfully."
    else
        log_message "ERROR" "Failed to check RAID status for $raid_device."
        exit 1
    fi
}

# Encrypt a disk using LUKS
encrypt_disk() {
    if [ $# -lt 1 ]; then
        echo "Error: Missing disk for encryption."
        usage
    fi
    local disk="$1"

    echo "Encrypting disk..."
    log_message "INFO" "Encrypting disk $disk with LUKS"

    cryptsetup luksFormat "$disk"
    if [ $? -eq 0 ]; then
        log_message "INFO" "Disk $disk encrypted successfully."
    else
        log_message "ERROR" "Failed to encrypt disk $disk."
        exit 1
    fi
}

# Open an encrypted disk
decrypt_disk() {
    if [ $# -lt 1 ]; then
        echo "Error: Missing encrypted disk name."
        usage
    fi
    local disk_name="$1"

    echo "Decrypting disk..."
    log_message "INFO" "Decrypting disk $disk_name"

    cryptsetup luksClose "$disk_name"
    if [ $? -eq 0 ]; then
        log_message "INFO" "Disk $disk_name decrypted successfully."
    else
        log_message "ERROR" "Failed to decrypt disk $disk_name."
        exit 1
    fi
}

# Repair RAID array
repair_raid() {
    echo "Repairing RAID array..."
    log_message "INFO" "Repairing RAID array."

    mdadm --assemble --scan
    if [ $? -eq 0 ]; then
        log_message "INFO" "RAID array repaired successfully."
    else
        log_message "ERROR" "Failed to repair RAID array."
        exit 1
    fi
}

# Key Management for LUKS
key_management() {
    if [ $# -lt 2 ]; then
        echo "Error: Missing arguments for key management."
        usage
    fi
    local disk="$1"
    local operation="$2"

    echo "Managing encryption keys..."
    log_message "INFO" "Managing encryption key for disk $disk"

    case "$operation" in
        add)
            cryptsetup luksAddKey "$disk"
            ;;
        remove)
            cryptsetup luksRemoveKey "$disk"
            ;;
        *)
            echo "Unknown key management operation: $operation"
            log_message "ERROR" "Unknown key management operation: $operation"
            exit 1
            ;;
    esac

    if [ $? -eq 0 ]; then
        log_message "INFO" "Encryption key for disk $disk managed successfully."
    else
        log_message "ERROR" "Failed to manage encryption key for disk $disk."
        exit 1
    fi
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
    decrypt)
        decrypt_disk "$2"
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

