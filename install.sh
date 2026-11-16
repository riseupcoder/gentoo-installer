#!/usr/bin/env bash

set -euo pipefail

# ============================================================
# Gentoo Installer
# ============================================================

readonly ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
readonly MOUNT_POINT="/mnt/gentoo"

# Load libraries
source "$ROOT_DIR/lib/logging.sh"
source "$ROOT_DIR/lib/common.sh"

# Load host scripts
source "$SCRIPTS_DIR/host/disks.sh"
source "$SCRIPTS_DIR/host/stage3.sh"

# Load target orchestrator
source "$SCRIPTS_DIR/target/base/setup.sh"

# ------------------------------------------------------------
# Installation mode
# ------------------------------------------------------------

echo
info "Gentoo Installation"
echo
printf '1) Fresh installation\n'
printf '2) Resume installation\n'
echo

read -r -p "Select installation mode: " MODE

case "$MODE" in
    1)
        prepare_disk
        mount_target_filesystems
        install_stage3
        ;;

    2)
        mount_target_filesystems
        ;;

    *)
        error "Invalid installation mode."
        exit 1
        ;;
esac

# ------------------------------------------------------------
# Target installation
# ------------------------------------------------------------

configure_base_system

echo
success "Gentoo installation completed successfully."
