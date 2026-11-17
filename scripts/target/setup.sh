#!/usr/bin/env bash

set -euo pipefail

# ============================================================
# Gentoo Target Configuration
# ============================================================

configure_dns() {
    info "Configuring DNS..."

    cp --dereference /etc/resolv.conf "$MOUNT_POINT/etc/"

    success "DNS configured."
}

generate_fstab() {
    info "Generating /etc/fstab..."

    genfstab -U "$MOUNT_POINT" > "$MOUNT_POINT/etc/fstab"

    success "/etc/fstab generated."
}

run_target_script() {
    local script="$1"
    shift

    require_file "$script"

    arch-chroot "$MOUNT_POINT" /bin/bash -s -- "$@" < "$script"
}

configure_base_system() {
    local root_uuid

    require_mount "$MOUNT_POINT"
    require_command arch-chroot

    # Export shared functions to the target Bash processes
    export -f info success warn error
    export -f require_file require_dir require_command require_mount

    configure_dns
    generate_fstab

    root_uuid=$(findmnt -no UUID "$MOUNT_POINT")

    [[ -n "$root_uuid" ]] || {
        error "Failed to determine root filesystem UUID."
        exit 1
    }

    info "Configuring Gentoo base system..."
    run_target_script "$SCRIPTS_DIR/target/base.sh"

    info "Installing and configuring kernel..."
    run_target_script "$SCRIPTS_DIR/target/kernel.sh" "$root_uuid"

    info "Configuring system..."
    run_target_script "$SCRIPTS_DIR/target/system.sh"

    info "Configuring users..."
    run_target_script "$SCRIPTS_DIR/target/user.sh"

    echo
    success "Gentoo target configuration complete."
}
