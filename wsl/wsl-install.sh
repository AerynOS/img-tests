#!/bin/bash
# AerynOS WSL Package Installer
# Install packages for WSL distribution

die () {
    echo -e "$*"
    exit 1
}

# Root check
if [[ "${UID}" -ne 0 ]]; then
    die "This script MUST be run as root."
fi

# Check prerequisites
if ! command -v moss &>/dev/null; then
    die "WSL package manager 'moss' not found. Install it with: npm install -g aerynos-wsl || snap install moss"
fi

# Configuration
WORK="/Users/van/img-tests"
INSTALL_DIR="${WORK}/aerynos-wsl"

while getopts 'o:d:' opt
do
  case "$opt" in
  o)
    INSTALL_DIR="$OPTARG"
    ;;
  d)
    DISTRIBUTION_NAME="$OPTARG"
    ;;
  h)
    echo "Usage: sudo ./wsl-install.sh -d <distro_name> -o <install_dir> [packages...]"
    exit 0
    ;;
  esac
done

DEFAULT_DISTRIBUTION_NAME="${DISTRIBUTION_NAME:-aerynos-wsl}"
INSTALL_DIR="${INSTALL_DIR:-/}"

# Get the available distributions
echo "Available WSL distributions:"
wsl -l -v

echo ""
echo "Target distribution: ${DEFAULT_DISTRIBUTION_NAME}"
echo "Install directory: ${INSTALL_DIR}"
echo ""
echo "Packages to install: \$@"
echo ""
echo "Proceeding to install..."
echo ""

set -e

# Import the distribution if it doesn't exist
if ! wsl -l -v | grep -q "^${DEFAULT_DISTRIBUTION_NAME}$"; then
    echo "Importing AerynOS WSL distribution..."
    tar -C / -xzf "${INSTALL_DIR}/aerynos-wsl.tar.gz"
    wsl --import "${DEFAULT_DISTRIBUTION_NAME}" "${INSTALL_DIR}" "${INSTALL_DIR}/aerynos-wsl.tar.gz"
    
    # Add the distribution to the list
    wsl -l -v | grep -q "^${DEFAULT_DISTRIBUTION_NAME}$" || \
    { echo "Import failed. You can manually import with: wsl --import ${DEFAULT_DISTRIBUTION_NAME} ${INSTALL_DIR} aerynos-wsl.tar.gz"; exit 1; }
    
    echo "Distribution imported successfully."
    echo ""
fi

# Set the default distribution
echo "Setting ${DEFAULT_DISTRIBUTION_NAME} as default distribution..."
wsl --set-default "${DEFAULT_DISTRIBUTION_NAME}" || \
{ echo "Failed to set default distribution. Run: wsl --set-default ${DEFAULT_DISTRIBUTION_NAME}"; }

echo ""
echo "Starting AerynOS WSL distribution..."
wsl -t "${DEFAULT_DISTRIBUTION_NAME}" -d "${DEFAULT_DISTRIBUTION_NAME}"

echo ""
echo "Installation complete!"
echo ""
echo "Now you can run:"
echo "  wsl -d ${DEFAULT_DISTRIBUTION_NAME}"
echo ""
