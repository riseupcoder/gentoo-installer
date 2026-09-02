#!/usr/bin/env bash

set -euo pipefail

# ============================================================
# Gentoo System Configuration
# ============================================================

SYSTEM_HOSTNAME="localhost"

mount_home() {

    info "Mounting home partition..."

    mkdir -p "$MOUNT_POINT/home"

    if ! mount "$HOME_PARTITION" "$MOUNT_POINT/home"; then
        error "Failed to mount home partition."
        exit 1
    fi

  #  mount "/dev/nvme0n1p3" "$MOUNT_POINT/home"

    success "Home partition mounted."
}

generate_fstab() {

    info "Generating /etc/fstab..."

    if ! genfstab -U "$MOUNT_POINT" \
        >> "$MOUNT_POINT/etc/fstab"; then

        error "Failed to generate /etc/fstab."
        exit 1
    fi

    success "/etc/fstab generated."
}

configure_hostname() {

    info "Configuring hostname..."

    if ! printf '%s\n' "$SYSTEM_HOSTNAME" \
        > "$MOUNT_POINT/etc/hostname"; then

        error "Failed to configure hostname."
        exit 1
    fi

    success "Hostname configured."
}

dhcpcd_setup() {

    info "Installing DHCP client..."

    if ! chroot_run 'emerge --verbose net-misc/dhcpcd'; then
        error "Failed to install dhcpcd."
        exit 1
    fi

    success "DHCP client installed."

    info "Enabling dhcpcd..."

    if ! chroot_run 'rc-update add dhcpcd default'; then
        error "Failed to enable dhcpcd."
        exit 1
    fi

    success "dhcpcd enabled."
}

set_root_password() {

    info "Setting root password..."

    if ! chroot_run 'passwd'; then
        error "Failed to set root password."
        exit 1
    fi

    success "Root password configured."
}

configure_system() {

    mount_home
    generate_fstab
    configure_hostname
    dhcpcd_setup
    set_root_password

    echo
    success "Gentoo system configuration complete."

}

