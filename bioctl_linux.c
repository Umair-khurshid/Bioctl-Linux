#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <time.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>

#define LOG_FILE "/var/log/bioctl_linux.log"

void log_message(const char *level, const char *message) {
    FILE *log = fopen(LOG_FILE, "a");
    if (log == NULL) return;

    time_t now = time(NULL);
    struct tm *t = localtime(&now);
    fprintf(log, "%04d-%02d-%02d %02d:%02d:%02d [%s] %s\n",
            t->tm_year + 1900, t->tm_mon + 1, t->tm_mday,
            t->tm_hour, t->tm_min, t->tm_sec, level, message);
    fclose(log);
}

void usage() {
    printf("Usage: bioctl {create|add|remove|status|encrypt|decrypt|repair|key-management} [options]\n");
    exit(1);
}

void handle_error(const char *message) {
    fprintf(stderr, "Error: %s\n", message);
    log_message("ERROR", message);
    usage();
}

int command_exists(const char *cmd) {
    char path[256];
    snprintf(path, sizeof(path), "/usr/bin/which %s > /dev/null 2>&1", cmd);
    return (system(path) == 0);
}

void create_raid(char **argv, int argc) {
    if (argc < 6) handle_error("Missing arguments for create.");
    const char *raid_device = argv[2];
    const char *raid_level = argv[3];
    const char *raid_disks = argv[4];

    char cmd[1024];
    snprintf(cmd, sizeof(cmd), "mdadm --create %s --level=%s --raid-devices=%s", raid_device, raid_level, raid_disks);
    for (int i = 5; i < argc; i++) {
        strcat(cmd, " ");
        strcat(cmd, argv[i]);
    }
    log_message("INFO", "Creating RAID array");
    if (system(cmd) != 0) handle_error("Failed to create RAID array");
}

void add_disk(char **argv) {
    if (!argv[2] || !argv[3]) handle_error("Missing arguments for add.");
    char cmd[256];
    snprintf(cmd, sizeof(cmd), "mdadm --add %s %s", argv[2], argv[3]);
    log_message("INFO", "Adding disk to RAID array");
    if (system(cmd) != 0) handle_error("Failed to add disk to RAID array");
}

void remove_disk(char **argv) {
    if (!argv[2] || !argv[3]) handle_error("Missing arguments for remove.");
    char cmd[256];
    snprintf(cmd, sizeof(cmd), "mdadm --remove %s %s", argv[2], argv[3]);
    log_message("INFO", "Removing disk from RAID array");
    if (system(cmd) != 0) handle_error("Failed to remove disk from RAID array");
}

void status_raid(char **argv) {
    if (!argv[2]) handle_error("Missing RAID device for status.");
    char cmd[256];
    snprintf(cmd, sizeof(cmd), "mdadm --detail %s", argv[2]);
    log_message("INFO", "Checking RAID status");
    if (system(cmd) != 0) handle_error("Failed to check RAID status");
}

void encrypt_disk(char **argv) {
    if (!argv[2]) handle_error("Missing disk for encryption.");
    char cmd[256];
    snprintf(cmd, sizeof(cmd), "cryptsetup luksFormat %s", argv[2]);
    log_message("INFO", "Encrypting disk");
    if (system(cmd) != 0) handle_error("Failed to encrypt disk");
}

void decrypt_disk(char **argv) {
    if (!argv[2]) handle_error("Missing encrypted disk name.");
    char cmd[256];
    snprintf(cmd, sizeof(cmd), "cryptsetup luksClose %s", argv[2]);
    log_message("INFO", "Decrypting disk");
    if (system(cmd) != 0) handle_error("Failed to decrypt disk");
}

void repair_raid() {
    log_message("INFO", "Repairing RAID array");
    if (system("mdadm --assemble --scan") != 0) handle_error("Failed to repair RAID array");
}

void key_management(char **argv) {
    if (!argv[2] || !argv[3]) handle_error("Missing arguments for key management.");
    char cmd[256];
    if (strcmp(argv[3], "add") == 0) {
        snprintf(cmd, sizeof(cmd), "cryptsetup luksAddKey %s", argv[2]);
    } else if (strcmp(argv[3], "remove") == 0) {
        snprintf(cmd, sizeof(cmd), "cryptsetup luksRemoveKey %s", argv[2]);
    } else {
        handle_error("Unknown key management operation");
    }
    log_message("INFO", "Managing encryption key");
    if (system(cmd) != 0) handle_error("Failed to manage encryption key");
}

int main(int argc, char **argv) {
    if (geteuid() != 0) {
        fprintf(stderr, "You must be root to run this program.\n");
        return 1;
    }

    if (argc < 2) usage();

    if (!command_exists("mdadm") || !command_exists("cryptsetup")) {
        handle_error("Required commands mdadm or cryptsetup not found.");
    }

    if (strcmp(argv[1], "create") == 0) create_raid(argv, argc);
    else if (strcmp(argv[1], "add") == 0) add_disk(argv);
    else if (strcmp(argv[1], "remove") == 0) remove_disk(argv);
    else if (strcmp(argv[1], "status") == 0) status_raid(argv);
    else if (strcmp(argv[1], "encrypt") == 0) encrypt_disk(argv);
    else if (strcmp(argv[1], "decrypt") == 0) decrypt_disk(argv);
    else if (strcmp(argv[1], "repair") == 0) repair_raid();
    else if (strcmp(argv[1], "key-management") == 0) key_management(argv);
    else usage();

    return 0;
}



