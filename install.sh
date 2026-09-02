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

# Load installation scripts
source "$SCRIPTS_DIR/01-disks.sh"
source "$SCRIPTS_DIR/02-stage3.sh"
source "$SCRIPTS_DIR/03-base.sh"
source "$SCRIPTS_DIR/04-kernel.sh"
source "$SCRIPTS_DIR/05-system.sh"
source "$SCRIPTS_DIR/06-user.sh"

# ------------------------------------------------------------
# Run installation
# ------------------------------------------------------------

prepare_disk

install_stage3

configure_base

install_kernel

configure_system

configure_user

echo
success "Gentoo installation completed successfully."
