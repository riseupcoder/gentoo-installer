#!/usr/bin/env bash

set -euo pipefail

# ============================================================
# Gentoo User Configuration
# ============================================================

create_user() {

    local username

    info "Creating user account..."

    read -r -p "Enter username: " username </dev/tty

    [[ -n "$username" ]] || {
        error "Username cannot be empty."
        exit 1
    }

    [[ "$username" =~ ^[a-z_][a-z0-9_-]*$ ]] || {
        error "Invalid username."
        exit 1
    }

    useradd -m -G users,wheel -s /bin/bash "$username"

    success "User '$username' created."

    info "Setting password for '$username'..."

    passwd "$username"

    success "User password configured."
}

configure_doas_use() {

    info "Configuring OpenDoas USE flags..."

    echo "app-admin/doas persist" > /etc/portage/package.use/doas

    success "OpenDoas USE flags configured."
}

install_doas() {

    info "Installing OpenDoas..."

    emerge --verbose app-admin/doas

    success "OpenDoas installed."
}

configure_doas() {

    info "Configuring OpenDoas..."

    echo "permit persist :wheel" > /etc/doas.conf

    chown root:root /etc/doas.conf
    chmod 0400 /etc/doas.conf

    doas -C /etc/doas.conf

    success "OpenDoas configured."
}

configure_user() {

    create_user
    configure_doas_use
    install_doas
    configure_doas

    echo
    success "User configuration complete."
}

configure_user
