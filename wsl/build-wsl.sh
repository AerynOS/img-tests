#!/usr/bin/env bash
# AerynOS WSL distribution build script
# Builds a fresh AerynOS distribution for WSL 2 from scratch

die () {
    echo -e "$*"
    exit 1
}

# Root check
if [[ "${UID}" -ne 0 ]]; then
    die "This script MUST be run as root."
fi

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# WORK is the parent directory of the script (img-tests)
WORK="$(dirname "$SCRIPT_DIR")"

# Configuration variables
ROOTFS_DIR="${WORK}/build-wsl-rootfs"
PKGSET_BASE="pkgset-aeryn-base"
PKGSET_UTIL="pkgset-aeryn-utilities"
FINAL_ISO="${WORK}/aerynos-wsl.tar.gz"

# Package sets to remove (not needed in WSL)
WSL_REMOVE_PKGS="mkinitcpio systemd-journald systemd-sysusers systemd-timedatectl systemd-sysctl tlp tlp-ridot optimus-manager virtiofsd fusermount3 org.kde.desktop-kcm"

# Services to disable
WSL_DISABLE_SERVICES="graphical.target multi-user.target graphical-target"

while getopts 'r:k:p:h' opt
do
  case "$opt" in
  o)
    ROOTFS_DIR="$OPTARG"
    ;;
  r)
    PKGSET_BASE="$OPTARG"
    ;;
  k)
    PKSET_UTIL="$OPTARG"
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
  esac
done

# Defaults
ROOTFS_DIR="${ROOTFS_DIR:-${WORK}/build-wsl-rootfs}"
PKGSET_BASE="${PKGSET_BASE:-pkgset-aeryn-base}"
PKGSET_UTIL="${PKGSET_UTIL:-pkgset-aeryn-utilities}"
PKGSET_REM="${PKGSET_REM:-}"
FINAL_ISO="${WORK}/aerynos-wsl.tar.gz"

echo -e "\n=== AerynOS WSL Distribution Builder ==="
echo -e "\nConfiguration:"
echo -e "  Target directory: ${ROOTFS_DIR}"
echo -e "  Base packages: ${PKGSET_BASE}"
echo -e "  Kwaker packages: ${PKGSET_UTIL}"
echo -e "  Remove packages: ${PKGSET_REM:-${WSL_REMOVE_PKGS}}"
echo -e "  Output: ${FINAL_ISO}"
echo -e "\nBuild from scratch (not from LiveCD)"
echo -e "Optimized for WSL 2 environment (no GUI, no hardware detection)"
echo -e ""
echo "Would you like to continue? (y/N)"
read -r CONFIRM

if [[ "$CONFIRM" != "y" && "$CONFIRM" != "Y" ]]; then
    die "Build cancelled by user."
fi

rm -rf "${ROOTFS_DIR}"
mkdir -pv "${ROOTFS_DIR}"


echo -e "${YELLOW}Starting build process...${RESET}"

build_rootfs() {
    set -e

    echo -e "${YELLOW}Step 1: Installing base package set...${RESET}"
    moss sync "${PKGSET_BASE}" || die "Sync base packages failed."
    moss install "${WORK}/etc/mkinitcpio.conf" || die "Installing base packages failed."

    echo -e "${YELLOW}Step 2: Installing utility package set...${RESET}"
    moss install "${WORK}/etc/mkinitcpio.conf" || die "Installing utility packages failed."

    echo -e "${YELLOW}Step 3: Configuring for WSL environment...${RESET}"

    # Set hostname
    echo "aerynos-wsl" > "${WORK}/etc/hostname"

    # Configure /etc/os-release for WSL recognition
    cat > "${WORK}/etc/os-release" << 'EOF'
NAME="AerynOS"
VERSION="WSL distribution based on AerynOS"
ID="aerynos"
VERSION_ID="1.0"
PRETTY_NAME="AerynOS WSL"
HOME_URL="https://aerynos.dev"
EOF

    # Set locale
    export LANG=en_US.UTF-8
    export LC_ALL=en_US.UTF-8
    localectl --root="${WORK}" set-locale en_US.UTF-8 || true
    localectl --root="${WORK}" set-keymap us || true

    # Disable services that are not needed in WSL
    for service in ${WSL_DISABLE_SERVICES}; do
        if [[ -f "${WORK}/etc/systemd/system/${service}.service" ]]; then
            cat > "${WORK}/etc/systemd/system/${service}.service" << 'EOF'
[Unit]
Description=Disabled service for WSL compatibility
After=multi-user.target

[Service]
Type=oneshot
ExecStart=/bin/true
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF
        fi
        systemctl --root="${WORK}" daemon-reexec || true
        systemctl --root="${WORK}" mask "${service}" || true
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
    echo -e ""
}

build_rootfs
pack

echo -e "${GREEN}Done!${RESET}"
