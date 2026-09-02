#!/usr/bin/env bash

set -euo pipefail

# ============================================================
# Gentoo Stage 3
# ============================================================

fetch_stage3_info() {

    local latest_url="https://distfiles.gentoo.org/releases/amd64/autobuilds/latest-stage3-amd64-openrc.txt"
    local latest_file="$MOUNT_POINT/latest-stage3-amd64-openrc.txt"

    info "Fetching latest Gentoo Stage 3 information..."

    if ! curl --tlsv1.3 -fsSL -o "$latest_file" "$latest_url"; then
        error "Failed to download Stage 3 metadata."
        exit 1
    fi

    success "Stage 3 metadata downloaded."
}

import_release_keys() {

    info "Importing Gentoo release signing keys..."

    if ! gpg --import /usr/share/openpgp-keys/gentoo-release.asc; then
        error "Failed to import Gentoo release signing keys."
        exit 1
    fi

    success "Gentoo release keys imported."
}

verify_stage3_info() {

    local latest_file="$MOUNT_POINT/latest-stage3-amd64-openrc.txt"

    info "Verifying Stage 3 metadata..."

    if ! gpg --verify "$latest_file"; then
        error "Stage 3 metadata verification failed."
        exit 1
    fi

    success "Stage 3 metadata verified."
}

get_stage3_path() {

    local latest_file="$MOUNT_POINT/latest-stage3-amd64-openrc.txt"

    STAGE_PATH=$(awk '$1 ~ /\.tar\.xz$/ {print $1; exit}' "$latest_file")

    if [[ -z "$STAGE_PATH" ]]; then
        error "Unable to determine the latest Stage 3 archive."
        exit 1
    fi

    STAGE_URL="https://distfiles.gentoo.org/releases/amd64/autobuilds/$STAGE_PATH"
    STAGE_FILE="${STAGE_PATH##*/}"

    info "Latest Stage 3: $STAGE_FILE"
}

download_stage3() {

    info "Downloading Gentoo Stage 3..."

    if ! curl --tlsv1.3 -fsSL -O "$STAGE_URL"; then
        error "Failed to download Stage 3."
        exit 1
    fi

    if ! curl --tlsv1.3 -fsSL -O "${STAGE_URL}.asc"; then
        error "Failed to download Stage 3 signature."
        exit 1
    fi

    if ! curl --tlsv1.3 -fsSL -O "${STAGE_URL}.sha256"; then
        error "Failed to download Stage 3 checksum."
        exit 1
    fi

    success "Stage 3 downloaded."
}

verify_stage3_signature() {

    info "Verifying Stage 3 signature..."

    if ! gpg --verify "${STAGE_FILE}.asc" "$STAGE_FILE"; then
        error "Stage 3 signature verification failed."
        exit 1
    fi

    success "Stage 3 signature verified."
}

verify_stage3_checksum() {

    info "Verifying Stage 3 checksum..."

    if ! sha256sum -c "${STAGE_FILE}.sha256"; then
        error "Stage 3 checksum verification failed."
        exit 1
    fi

    success "Stage 3 checksum verified."
}

extract_stage3() {

    info "Extracting Stage 3..."

    if ! tar xpvf "$STAGE_FILE" \
        --xattrs-include='*.*' \
        --numeric-owner \
        -C "$MOUNT_POINT"; then

        error "Failed to extract Stage 3."
        exit 1
    fi

    success "Stage 3 extracted."
}

calculate_makeopts() {

    local ram_gib
    local jobs

    ram_gib=$(awk '/MemTotal/ {printf "%d\n", $2 / 1024 / 1024}' /proc/meminfo)

    jobs=$(( (ram_gib - 2) / 2 ))
    (( jobs < 1 )) && jobs=1

    MAKEOPTS="-j${jobs}"

    info "Detected RAM: ${ram_gib} GiB"
    info "Using MAKEOPTS: ${MAKEOPTS}"
}

configure_make_conf() {

    local make_conf="$MOUNT_POINT/etc/portage/make.conf"

    info "Configuring make.conf..."

    if ! sed -i \
        's/^COMMON_FLAGS="-O2 -pipe"$/COMMON_FLAGS="-O2 -pipe -march=x86-64-v3"/' \
        "$make_conf"; then

        error "Failed to configure COMMON_FLAGS."
        exit 1
    fi

    if ! cat >> "$make_conf" <<EOF

# Gentoo installer custom configuration
ACCEPT_LICENSE="-* @FREE"
FEATURES="getbinpkg binpkg-request-signature"
USE="dist-kernel"
MAKEOPTS="$MAKEOPTS"
EOF
    then
        error "Failed to update make.conf."
        exit 1
    fi

    success "make.conf configured."
}


# ------------------------------------------------------------
# Stage 3 installation
# ------------------------------------------------------------

install_stage3() {

    cd "$MOUNT_POINT"

    fetch_stage3_info
    import_release_keys
    verify_stage3_info
    get_stage3_path
    download_stage3
    verify_stage3_signature
    verify_stage3_checksum
    extract_stage3
    calculate_makeopts
    configure_make_conf

    echo
    success "Gentoo Stage 3 installation complete."
}

