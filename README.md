# Bioctl linux 
`bioctl_linux` is a command-line tool inspired by OpenBSD's `bioctl` utility, designed to manage RAID configurations and disk encryption on Linux systems. It provides functionality for monitoring RAID arrays, managing encrypted volumes, and adding RAID encryption key management.

## Features

-   **RAID Management**: Monitor RAID arrays, check status, and get alerts if a disk is missing or if the array is degraded.
-   **Disk Encryption**: Manage encrypted volumes using LUKS, including key management.
-   **Flexible RAID Levels**: Supports RAID 0, RAID 1, and can be extended to support RAID 5, RAID 6, etc.
-   **Logging**: Tracks changes and errors in RAID and encryption setups with logging capabilities.


## Prerequisites

Before using `bioctl_linux`, ensure the following packages are installed on your system:

-   `mdadm` (for RAID management)
-   `cryptsetup` (for disk encryption)
-   `lvm2` (if using Logical Volume Management)
-   `bash` (for running the script)

Install these using:

`
sudo apt update && sudo apt install mdadm cryptsetup lvm2
`

## Installation

1.  **Clone the repository**:
    
   ```
   git clone https://github.com/Umair-khurshid/bioctl-linux.git
   cd bioctl-linux
```
    
2.  **Make the script executable**:
    
   `chmod +x bioctl_linux.sh
   `
    

## **Usage**

### **Basic Commands**

-   **Check RAID status**:
    
 
  `sudo ./bioctl_linux.sh --check-raid` 
    
-   **Encrypt a new disk**:

   `sudo ./bioctl_linux.sh --encrypt-disk /dev/sdX` 
    
-   **Add a new encryption key**:
    
   `sudo ./bioctl_linux.sh --add-key /dev/sdX` 
    
-   **Remove an encryption key**:
   
`sudo ./bioctl_linux.sh --remove-key /dev/sdX`
    
### Example Usage

-   **Create a RAID 1 array**:
    
    `sudo ./bioctl_linux.sh --create-raid --level 1 --devices /dev/sdX,/dev/sdY` 
    
-   **Check if the RAID array is degraded**:
    
    `sudo ./bioctl_linux.sh --check-degraded` 
    
-   **Monitor RAID and encryption status with logging**:
    
    `sudo ./bioctl_linux.sh --monitor`

## **Logging**

By default, the script logs its actions and errors to `/var/log/bioctl_linux.log`. You can modify the log file location by editing the script.

## **Error Handling**

The script includes error handling for:

-   Missing disks in RAID arrays.
-   Degraded RAID status.
-   Issues during LUKS encryption key management.
-   Invalid or unsupported RAID levels.
