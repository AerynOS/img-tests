#!/usr/bin/env bash
#
# SPDX-FileCopyrightText: © 2025 AerynOS Developers
#
# SPDX-License-Identifier: MPL-2.0
#
# AerynOS WSL initrd builder
# Builds initrd for WSL distribution
#

die () {
    echo -e "$*"
    exit 1
}

# Root check
if [[ "${UID}" -ne 0 ]]; then
    die "This script MUST be run as root."
fi

# Configuration
WORK="/Users/van/img-tests/wsl"
INITRD_OUTPUT="${WORK}/initrd.aerynos-wsl"
INITRD_PACKAGES="binary(dash) dracut"

TMPFS="/tmp/aerynos-wsl-initrd"
rm -rf "${TMPFS}"/*

echo ">>>"
echo "Working directory: ${TMPFS}"
echo ""
echo "Packages: ${INITRD_PACKAGES}"
echo ""
echo "Building initrd for AerynOS WSL..."
echo ""

set -e

echo -e "${YELLOW}Step 1: Creating initrd kernel image...${RESET}"
mkdir -pv "${TMPFS}/initrd"

echo -e "${YELLOW}Step 2: Installing initrd packages...${RESET}"
moss install ${INITRD_PACKAGES} -t "${TMPFS}" || die "Installing initrd packages failed."

echo -e "${YELLOW}Step 3: Regenerating initrd...${RESET}"
kver=$(ls "${TMPFS}/usr/lib/modules" | head -1)
export RUST_BACKTRACE=1
echo "Kernel: ${kver}"

# Generate initrd for WSL - similar to dracut
cat > "${TMPFS}/usr/lib/tmpfiles.d/initrd.conf" << 'EOF'
# Binary mode
_d 0 0 0 dev null 0755
_d 0 0 0 dev/null 0755
_d 0 0 0 /dev/console 0755
_d 0 0 0 /dev/kmsg 0600
_u root root /dev/shm 1777
EOF

echo -e "${YELLOW}Step 4: Generating initrd...${RESET}"

# Use systemd-geninitrd or mkinitcpio
if command -v systemd-geninitrd &> /dev/null; then
    systemd-geninitrd --minimal -d "${TMPFS}" --output "${INITRD_OUTPUT}" || die "systemd-geninitrd failed."
else
    # Fallback: use mkinitcpio
    export CDEBUG_PREFIX=${INITRD_OUTPUT}
    mkinitcpio -p linux --microcode /usr/share/uboot/ -O "${INITRD_OUTPUT}" || die "mkinitcpio failed."
    mv -v "${INITRD_OUTPUT}" "${INITRD_OUTPUT}.orig"
    INITRD_OUTPUT="${INITRD_OUTPUT}.orig"
fi

echo -e "${GREEN}Initrd created: ${INITRD_OUTPUT}${RESET}"
echo ""
echo -e "${YELLOW}Size: $(du -h "${INITRD_OUTPUT}" | cut -f1)${RESET}"
