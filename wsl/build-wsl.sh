#!/usr/bin/env bash
#
# SPDX-FileCopyrightText: © 2025 AerynOS Developers
#
# SPDX-License-Identifier: MPL-2.0
#
# AerynOS WSL distribution build script
# Builds a fresh AerynOS distribution for WSL 2 from scratch
# Not from LiveCD, optimized for WSL environment

die () {
    echo -e "$*"
    exit 1
}

# Root check
if [[ "${UID}" -ne 0 ]]; then
    die "This script MUST be run as root."
fi

# Add escape codes for color
RED='\033[0;31m'
RESET='\033[0m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'

# Configuration variables
WORK="/Users/van/img-tests"
ROOTFS_DIR="${WORK}/build-wsl-rootfs"
PKGSET_BASE="pkgset-aeryn-base"
PKGSET_UTIL="pkgset-aeryn-utilities"
FINAL_ISO="${WORK}/aerynos-wsl.tar.gz"

# Package sets to remove (not needed in WSL)
WSL_REMOVE_PKGS="mkinitcpio systemd-journald systemd-sysusers systemd-timedatectl systemd-sysctl tlp tlp-rdw optimus-manager virtiofsd fusermount3 org.kde.desktop-kcm"

# Services to disable
WSL_DISABLE_SERVICES="graphical.target multi-user.target graphical-target"

do
  case "$opt" in
  o)
    ROOTFS_DIR="$OPTARG"
    ;;
  r)
    PKGSET_BASE="$OPTARG"
    ;;
  k)
    PKGSET_UTIL="$OPTARG"
    ;;
  p)
    PKSET_REM="$OPTARG"
    ;;
  h)
    echo -e "\nUsage: sudo ./build-wsl.sh -r <pkgset> -k <pkgset> [-p <extra pkgs to remove>] [-o <output>]"
    echo -e "\nThis script builds a fresh AerynOS distribution for WSL 2."
    echo -e "It installs packages directly and creates a tar.gz for WSL import."
    echo -e "\nOptions:"
    echo -e "  -r, --base    Base package set to install (default: pkgset-aeryn-base)"
    echo -e "  -k, --kwaker  Kwaker package set to install for updates (default: pkgset-aeryn-utilities)"
    echo -e "  -p, --prune   Extra packages to prune (overrides default WSL-specific removals)"
    echo -e "  -o, --output  Output filename (default: aerynos-wsl.tar.gz)"
    echo -e "\nDefaults:"
    echo -e "  -r: pkgset-aeryn-base"
    echo -e "  -k: pkgset-aeryn-utilities"
    exit 0
    ;;
done


    echo -e "${YELLOW}Step 4: Removing WSL-incompatible packages...${RESET}"
    if [[ -n "${PKGSET_REM}" ]]; then
        moss prune ${PKGSET_REM} || true
    fi
    moss prune ${WSL_REMOVE_PKGS} || true

    echo -e "${YELLOW}Step 5: Creating WSL-required directories...${RESET}"
    mkdir -p "${WORK}/dev" "${WORK}/proc" "${WORK}/sys" "${WORK}/run"
    
    # Create minimal device files
    makedevs || die "Creating device files failed."

    # Create /etc/machine-id for WSL
    head -c 32 /dev/urandom | base64 > "${WORK}/etc/machine-id"

    echo -e "${YELLOW}Step 6: Creating user...${RESET}"
    useradd -c "AerynOS User" -d "/home/aerynos" -G "audio,adm,wheel,render,input,users" -m -U -s "/usr/bin/bash" aerynos || true
    usermod -aG "sudo" aerynos || true
    passwd -d aerynos || true

    echo -e "${GREEN}Step 7: Root filesystem ready at ${WORK}${RESET}"

    # Show package list
    echo -e "${YELLOW}Installed packages:${RESET}"
    count=$(wc -l < "${WORK}/var/cache/moss/packages" | tr -d ' ')
    echo -e "  Total: ${count} packages"
}

pack() {
    echo -e "${YELLOW}Packaging rootfs for WSL...${RESET}"

    cd "${WORK}"

    # Compress with gzip for WSL
    tar -czf "${FINAL_ISO}" .

    echo -e "${GREEN}Build complete!${RESET}"
    echo -e "${YELLOW}Output: ${FINAL_ISO}${RESET}"
    echo -e ""
    echo -e "On Windows, run: wsl --import AerynOS <install_dir> ${FINAL_ISO}"
    echo -e ""
    echo -e "Then start it: wsl -d AerynOS"
    echo -e ""
    echo -e "${YELLOW}First boot instructions:${RESET}"
    echo -e "  - Run: wsl -d AerynOS"
    echo -e "  - Create user if needed:"
    echo -e "    sudo useradd -m your_username"
    echo -e "    sudo passwd your_username"
    echo -e "    sudo usermod -aG sudo your_username"
    echo -e "  - Or just login as 'aerynos'"
    echo -e ""
    echo -e "${YELLOW}Post-install tasks:${RESET}"
    echo -e "  - sudo moss sync -u  # Update package index"
    echo -e "  - sudo moss install <packages>  # Install more packages"
}

build_rootfs
pack

echo -e "${GREEN}Done!${RESET}"
