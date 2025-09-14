# Guide: Creating a Custom WSL Distribution from AerynOS LiveCD ISO

This document details the process of extracting the root filesystem from the `AerynOS-2025.08-GNOME-live-x86_64.iso` LiveCD image and creating a custom Windows Subsystem for Linux (WSL) distribution from it.

## 1. Prerequisites

Before you begin, ensure your system meets the following requirements:

- **A Linux host environment** (physical machine, virtual machine, or container): For mounting and extracting the ISO contents.
  - The `squashfs-tools` or `p7zip-full` packages must be installed.
  - `rsync` and `tar` must be installed.
- **Windows 10 or Windows 11**: Must support WSL 2.
- **WSL Enabled**: Run `wsl --install` in Windows as Administrator to ensure the WSL feature is enabled.
- **AerynOS ISO file**: `AerynOS-2025.08-GNOME-live-x86_64.iso`.

## 2. Steps in the Linux Environment

All the following commands need to be executed in a Linux environment, potentially with `sudo` privileges.

### 2.1 Mount the ISO File

```bash
# Create a mount point and mount the ISO
sudo mkdir -p /mnt/iso
sudo mount -o loop /path/to/your/AerynOS-2025.08-GNOME-live-x86_64.iso /mnt/iso
```

### 2.2 Explore ISO Structure and Extract Root Filesystem

After mounting, examine the ISO structure. The AerynOS root filesystem is typically located at `LiveOS/squashfs.img`.

```bash
# View ISO contents
ls -la /mnt/iso/
```

Use `unsquashfs` (preferred) or `7z` (alternative) to extract the root filesystem:

```bash
# Method 1: Using unsquashfs (Recommended)
mkdir ~/aerynos-rootfs
sudo unsquashfs -f -d ~/aerynos-rootfs /mnt/iso/LiveOS/squashfs.img

# Method 2: If unsquashfs fails (e.g., due to zstd compression), use 7z
sudo apt-get install p7zip-full # If not installed
mkdir ~/aerynos-rootfs
cd ~/aerynos-rootfs
7z x /mnt/iso/LiveOS/squashfs.img
# Note: 7z might extract multiple files. The root filesystem is usually in the largest archive file (e.g., LiveOS/rootfs.img) and might need a second extraction step.
# If it extracts a rootfs.img file (which is an image), you might need to mount it:
    sudo mount -o loop /path/to/extracted/rootfs.img /mnt/rootfs
    sudo rsync -a /mnt/rootfs/ ~/aerynos-rootfs/
    sudo umount /mnt/rootfs
```

**(Crucial Step)** Regardless of the method, the final goal is to have the complete root filesystem contents placed in the `~/aerynos-rootfs/` directory.

### 2.3 Clean Up the Filesystem (Optimize for WSL)

WSL containers use the host machine's kernel, so files unnecessary for the host must be removed.

```bash
cd ~/aerynos-rootfs

# Remove kernel and boot files
sudo rm -rf boot/*

# Clear temporary files, caches, and logs
sudo rm -rf tmp/* var/tmp/* var/log/* var/cache/*

# Remove system-specific identifiers and configurations
sudo rm -f etc/machine-id
sudo rm -rf var/lib/dhcp/* var/lib/NetworkManager/*
sudo rm -f var/lib/dbus/machine-id

# Remove device files (WSL will create its own)
sudo rm -rf dev/*

# Create empty directory structure required by WSL
sudo mkdir -p dev proc sys run

# (Optional but Recommended) Create an initialization script for WSL
sudo cat > init << 'EOF'
#!/bin/sh
exec /bin/bash "$@"
EOF
sudo chmod +x init

# (Optional) Remove documentation and man pages to reduce size
# sudo rm -rf usr/share/doc/* usr/share/man/*
```

### 2.4 Create the WSL Import Package

Package the cleaned root filesystem into a `tar` archive, which is the format required for WSL import.

```bash
cd ~
sudo tar -czf aerynos-wsl.tar.gz -C aerynos-rootfs .
```

Now, transfer the generated `aerynos-wsl.tar.gz` file to your Windows system.

## 3. Steps on Windows

### 3.1 Import into WSL

Execute the following command in Windows PowerShell or Command Prompt:

```powershell
# Replace <PathToTarGz> with the actual path to aerynos-wsl.tar.gz
# Replace <InstallLocation> with your desired install path for AerynOS (e.g., D:\WSL\AerynOS)
wsl --import AerynOS <InstallLocation> <PathToTarGz>
```
Example:
```powershell
wsl --import AerynOS D:\WSL\AerynOS D:\Users\van\Downloads\aerynos-wsl.tar.gz
```

### 3.2 Verify and Manage the WSL Distribution

After successful import, use the following commands for management:

```powershell
# List all installed WSL distributions and their status
wsl -l -v

# Start the AerynOS distribution
wsl -d AerynOS

# Set AerynOS as the default distribution (Optional)
wsl --set-default AerynOS
# Or use the shorthand
wsl -s AerynOS

# Terminate the AerynOS distribution
wsl -t AerynOS
```

## 4. First Run and Next Steps

1.  Use `wsl -d AerynOS` to start your custom distribution.
2.  You might need to update the package index and upgrade installed packages (use the package manager commands native to AerynOS, e.g., `sudo moss sync -u`).
3.  Install other software as needed.
4.  (Optional) Create a new user inside AerynOS and configure it as the default login user.

## 5. Important Notes

- **Space Requirements**: The extraction and build process requires sufficient disk space.
- **System Differences**: AerynOS's package manager and init system might differ from other distributions; adjust commands accordingly.
- **Hardware Support**: Certain specific hardware features might be unavailable in the WSL environment.
- **Backup**: Consider using `wsl --export` to back up your WSL distribution before making significant changes.

---

**Summary**: By following these steps, you can successfully convert the AerynOS LiveCD into a custom distribution that runs within WSL 2. The core of this process lies in correctly extracting and cleaning the root filesystem from the ISO and then using WSL's import functionality to integrate it into Windows.