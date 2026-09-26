#!/usr/bin/env bash

set -euo pipefail

# ============================================================
# Gentoo Base System
# ============================================================

configure_dns() {

    info "Configuring DNS..."

    if ! cp --dereference /etc/resolv.conf "$MOUNT_POINT/etc/"; then
        error "Failed to copy resolv.conf."
        exit 1
    fi

    success "DNS configured."
}

update_repository() {

    info "Updating Gentoo repository..."

    if ! chroot_run 'emerge-webrsync'; then
        error "Failed to update Gentoo repository."
        exit 1
    fi

    success "Gentoo repository updated."
}

configure_binrepo() {

    local binrepo_dir="$MOUNT_POINT/etc/portage/binrepos.conf"
    local binrepo_conf="$binrepo_dir/gentoo.conf"

    info "Configuring binary package repository..."

    if ! mkdir -p "$binrepo_dir"; then
        error "Failed to create binrepos.conf directory."
        exit 1
    fi

    if ! cat > "$binrepo_conf" <<'EOF'
[gentoo-x86-64-v3]
priority = 9999
sync-uri = https://distfiles.gentoo.org/releases/amd64/binpackages/23.0/x86-64-v3/
verify-signature = true
location = /var/cache/binhost/gentoo-x86-64-v3
EOF
    then
        error "Failed to configure binary package repository."
        exit 1
    fi

    success "Binary package repository configured."
}

initialize_binrepo() {

    info "Initializing binary package verification..."

    if ! chroot_run 'getuto'; then
        error "Failed to initialize binary package verification."
        exit 1
    fi

    success "Binary package verification initialized."
}

update_world() {

    info "Updating @world using binary packages..."

    if ! chroot_run \
        'emerge --verbose --update --deep --changed-use --getbinpkg @world'; then

        error "Failed to update @world."
        exit 1
    fi

    success "@world updated."
}

cleanup_packages() {

    info "Removing unnecessary packages..."

    if ! chroot_run 'emerge --depclean'; then
        error "Failed to perform depclean."
        exit 1
    fi

    success "Unnecessary packages removed."
}

configure_timezone() {

    info "Configuring timezone..."

    if ! chroot_run \
        'ln -sf ../usr/share/zoneinfo/UTC /etc/localtime'; then

        error "Failed to configure timezone."
        exit 1
    fi

    success "Timezone set to UTC."
}

configure_locale() {

    info "Configuring locale..."

    if ! chroot_run \
        'echo " en_US " >> /etc/locale.gen'; then

        error "Failed to configure /etc/locale.gen."
        exit 1
    fi

   # if ! chroot_run 'locale-gen'; then
   #     error "Failed to generate locale."
   #     exit 1
   # fi
   chroot_run 'locale-gen && sleep 5'

    if ! chroot_run \
        'printf "%s\n" '\''LANG="en_US.UTF-8"'\'' >> /etc/env.d/02locale'; then

        error "Failed to configure system locale."
        exit 1
    fi

    success "Locale configured."
}

update_environment() {

    info "Updating environment..."

    if ! chroot_run '
        env-update
        source /etc/profile
    '; then

        error "Failed to update environment."
        exit 1
    fi

    success "Environment updated."
}

configure_base() {

    configure_dns
    update_repository
    configure_binrepo
    initialize_binrepo
    update_world
    configure_timezone
    configure_locale
    update_environment

    echo
    success "Gentoo base system configuration complete."
}

