#!/usr/bin/env bash

set -euo pipefail

# ============================================================
# Gentoo User Configuration
# ============================================================

create_user() {

    info "Creating user account..."

    read -rp "Enter username: " USERNAME

    if [[ -z "$USERNAME" ]]; then
        error "Username cannot be empty."
        exit 1
    fi

    if [[ ! "$USERNAME" =~ ^[a-z_][a-z0-9_-]*$ ]]; then
        error "Invalid username."
        exit 1
    fi

    if ! chroot_run \
        "useradd -m -G users,wheel -s /bin/bash '$USERNAME'"; then

        error "Failed to create user account."
        exit 1
    fi

    success "User '$USERNAME' created."
}

set_user_password() {

    info "Setting password for '$USERNAME'..."

    if ! chroot_run "passwd '$USERNAME'"; then
        error "Failed to set user password."
        exit 1
    fi

    success "User password configured."
}

configure_doas_use() {

    local DOAS_USE_DIR="$MOUNT_POINT/etc/portage/package.use"
    local DOAS_USE="$DOAS_USE_DIR/doas"

    info "Configuring OpenDoas USE flags..."

    if ! mkdir -p "$DOAS_USE_DIR"; then
        error "Failed to create package.use directory."
        exit 1
    fi

    if ! printf '%s\n' \
        'app-admin/doas persist' \
        > "$DOAS_USE"; then

        error "Failed to configure OpenDoas USE flags."
        exit 1
    fi

    success "OpenDoas USE flags configured."
}

install_doas() {

    info "Installing OpenDoas..."

    if ! chroot_run 'emerge --verbose app-admin/doas'; then
        error "Failed to install OpenDoas."
        exit 1
    fi

    success "OpenDoas installed."
}

# ------------------------------------------------------------
# Configure OpenDoas
# ------------------------------------------------------------

configure_doas() {

    info "Configuring OpenDoas..."

    if ! chroot_run 'touch /etc/doas.conf'; then
        error "Failed to create /etc/doas.conf."
        exit 1
    fi

    if ! chroot_run \
        'printf "%s\n" "permit persist :wheel" > /etc/doas.conf'; then

        error "Failed to configure /etc/doas.conf."
        exit 1
    fi

    if ! chroot_run \
        'chown root:root /etc/doas.conf && chmod 0400 /etc/doas.conf'; then

        error "Failed to secure /etc/doas.conf."
        exit 1
    fi

    success "OpenDoas configured."
}

configure_user() {

    create_user
    set_user_password
    configure_doas_use
    install_doas
    configure_doas

    echo
    success "User configuration complete."
}

