#!/usr/bin/env bash
#---------------------------------------------------------------------------------------------------------
# Copyright (c) Pablo Zaiden. All rights reserved.
# Licensed under the MIT License. See https://go.microsoft.com/fwlink/?linkid=2090316 for license information.
#---------------------------------------------------------------------------------------------------------
#
# Maintainer: Pablo Zaiden
#
# Installs Bun - an all-in-one JavaScript runtime & toolkit
# https://bun.sh

set -e

# Options from devcontainer-feature.json
# Note: We use BUN_VERSION to avoid conflict with VERSION from /etc/os-release
BUN_VERSION="${VERSION:-"latest"}"

# Installation directory - use /usr/local for global access
export BUN_INSTALL="/usr/local"

echo "Installing Bun version: ${BUN_VERSION}"

# Must run as root
if [ "$(id -u)" -ne 0 ]; then
    echo 'Script must be run as root. Use sudo, su, or add "USER root" to your Dockerfile before this feature.'
    exit 1
fi

# Determine the appropriate non-root user
if [ "${USERNAME}" = "auto" ] || [ "${USERNAME}" = "automatic" ]; then
    USERNAME=""
    POSSIBLE_USERS=("vscode" "node" "codespace" "$(awk -v val=1000 -F ":" '$3==val{print $1}' /etc/passwd)")
    for CURRENT_USER in "${POSSIBLE_USERS[@]}"; do
        if id -u "${CURRENT_USER}" > /dev/null 2>&1; then
            USERNAME=${CURRENT_USER}
            break
        fi
    done
    if [ "${USERNAME}" = "" ]; then
        USERNAME=root
    fi
elif [ "${USERNAME}" = "none" ] || ! id -u ${USERNAME} > /dev/null 2>&1; then
    USERNAME=root
fi

# Detect OS and set up package manager
detect_os_and_package_manager() {
    # Source OS release info
    if [ -f /etc/os-release ]; then
        . /etc/os-release
    fi

    # Determine package manager
    if type apt-get > /dev/null 2>&1; then
        PACKAGE_MANAGER="apt-get"
        INSTALL_CMD="apt-get install -y --no-install-recommends"
        UPDATE_CMD="apt-get update -y"
        CLEANUP_CMD="rm -rf /var/lib/apt/lists/*"
    elif type apk > /dev/null 2>&1; then
        PACKAGE_MANAGER="apk"
        INSTALL_CMD="apk add --no-cache"
        UPDATE_CMD=""
        CLEANUP_CMD=""
    elif type dnf > /dev/null 2>&1; then
        PACKAGE_MANAGER="dnf"
        INSTALL_CMD="dnf install -y"
        UPDATE_CMD=""
        CLEANUP_CMD="rm -rf /var/cache/dnf/*"
    elif type yum > /dev/null 2>&1; then
        PACKAGE_MANAGER="yum"
        INSTALL_CMD="yum install -y"
        UPDATE_CMD=""
        CLEANUP_CMD="rm -rf /var/cache/yum/*"
    elif type zypper > /dev/null 2>&1; then
        PACKAGE_MANAGER="zypper"
        INSTALL_CMD="zypper install -y"
        UPDATE_CMD=""
        CLEANUP_CMD="rm -rf /var/cache/zypp/*"
    else
        echo "ERROR: Unable to find a supported package manager (apt-get, apk, dnf, yum, zypper)."
        exit 1
    fi
}

# Check if packages are installed, install if not
check_packages() {
    case ${PACKAGE_MANAGER} in
        apt-get)
            if ! dpkg -s "$@" > /dev/null 2>&1; then
                if [ -n "${UPDATE_CMD}" ]; then
                    ${UPDATE_CMD}
                fi
                ${INSTALL_CMD} "$@"
            fi
            ;;
        apk)
            ${INSTALL_CMD} "$@"
            ;;
        dnf|yum|zypper)
            ${INSTALL_CMD} "$@"
            ;;
    esac
}

# Clean up package manager caches
cleanup() {
    if [ -n "${CLEANUP_CMD}" ]; then
        ${CLEANUP_CMD}
    fi
}

# Detect architecture
detect_architecture() {
    local arch
    arch="$(uname -m)"
    case "${arch}" in
        x86_64)
            ARCH="x64"
            ;;
        aarch64 | arm64)
            ARCH="aarch64"
            ;;
        *)
            echo "ERROR: Unsupported architecture: ${arch}"
            echo "Bun supports x86_64 (amd64) and aarch64 (arm64) architectures."
            exit 1
            ;;
    esac
}

# Install Bun using the official installer
install_bun() {
    local install_script
    
    # Create temporary directory for installation
    local tmp_dir
    tmp_dir=$(mktemp -d)
    
    echo "Downloading Bun installer..."
    
    # Download the official installer
    curl -fsSL https://bun.sh/install -o "${tmp_dir}/install.sh"
    
    # Make installer executable
    chmod +x "${tmp_dir}/install.sh"
    
    # Prepare version argument
    local version_arg=""
    if [ "${BUN_VERSION}" = "latest" ]; then
        version_arg=""
    elif [ "${BUN_VERSION}" = "canary" ]; then
        version_arg="canary"
    else
        # Handle if user provides version with or without prefix
        if [[ "${BUN_VERSION}" == bun-v* ]]; then
            version_arg="${BUN_VERSION}"
        elif [[ "${BUN_VERSION}" == v* ]]; then
            version_arg="bun-${BUN_VERSION}"
        else
            version_arg="bun-v${BUN_VERSION}"
        fi
    fi
    
    echo "Installing Bun ${BUN_VERSION} to ${BUN_INSTALL}..."
    
    # Run the installer with appropriate arguments
    if [ -n "${version_arg}" ]; then
        BUN_INSTALL="${BUN_INSTALL}" bash "${tmp_dir}/install.sh" "${version_arg}"
    else
        BUN_INSTALL="${BUN_INSTALL}" bash "${tmp_dir}/install.sh"
    fi
    
    # Clean up temporary directory
    rm -rf "${tmp_dir}"
    
    # Verify installation
    if [ -x "${BUN_INSTALL}/bin/bun" ]; then
        echo "Bun installed successfully!"
        "${BUN_INSTALL}/bin/bun" --version
    else
        echo "ERROR: Bun installation failed - binary not found at ${BUN_INSTALL}/bin/bun"
        exit 1
    fi
}

# Set up environment for all users
setup_environment() {
    # The BUN_INSTALL environment variable is already set via containerEnv in devcontainer-feature.json
    # and /usr/local/bin should already be in PATH for most systems
    
    # Create a profile script to ensure BUN_INSTALL is set
    cat > /etc/profile.d/bun.sh << 'EOF'
export BUN_INSTALL="/usr/local"
EOF
    chmod +x /etc/profile.d/bun.sh
    
    echo "Environment configured for all users."
}

# Main installation flow
main() {
    detect_os_and_package_manager
    detect_architecture
    
    echo "Detected package manager: ${PACKAGE_MANAGER}"
    echo "Detected architecture: ${ARCH}"
    
    # Install required dependencies
    echo "Installing dependencies..."
    case ${PACKAGE_MANAGER} in
        apt-get)
            check_packages curl unzip ca-certificates
            ;;
        apk)
            check_packages curl unzip ca-certificates bash
            ;;
        dnf|yum)
            check_packages curl unzip ca-certificates
            ;;
        zypper)
            check_packages curl unzip ca-certificates
            ;;
    esac
    
    # Install Bun
    install_bun
    
    # Set up environment
    setup_environment
    
    # Clean up
    cleanup
    
    echo "Bun ${BUN_VERSION} installation complete!"
}

# Run main function
main
