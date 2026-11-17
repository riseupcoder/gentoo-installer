#!/usr/bin/env bash

set -euo pipefail

# ============================================================
# Gentoo System Configuration
# ============================================================

SYSTEM_HOSTNAME="localhost"

configure_hostname() {
    info "Configuring hostname..."

    echo "$SYSTEM_HOSTNAME" > /etc/hostname

    success "Hostname configured."
}

install_dhcpcd() {
    info "Installing DHCP client..."

    emerge --verbose net-misc/dhcpcd

    info "Enabling dhcpcd..."

    rc-update add dhcpcd default

    success "dhcpcd installed and enabled."
}

set_root_password() {
    info "Setting root password..."

    passwd < /dev/tty

    success "Root password configured."
}

configure_system() {
    configure_hostname
    install_dhcpcd
    set_root_password

    echo
    success "Gentoo system configuration complete."
}

configure_system
