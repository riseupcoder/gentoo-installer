#!/usr/bin/env bash

set -euo pipefail

# ============================================================
# Gentoo Stage 3
# ============================================================

readonly STAGE3_NAME="amd64-hardened-selinux-openrc"
readonly STAGE3_BASE_URL="https://distfiles.gentoo.org/releases/amd64/autobuilds"
readonly DOWNLOAD_DIR="$ROOT_DIR/downloads/stage3"
readonly STAGE3_INFO_FILE="$DOWNLOAD_DIR/latest-stage3-${STAGE3_NAME}.txt"
readonly STAGE3_MARKER="$MOUNT_POINT/.gentoo-stage3-installed"

readonly STAGE3_INFO_URL="${STAGE3_BASE_URL}/latest-stage3-${STAGE3_NAME}.txt"

# ------------------------------------------------------------
# Download and verification
# ------------------------------------------------------------

fetch_stage3_info() {
    info "Fetching latest Gentoo Stage 3 information..."

    mkdir -p "$DOWNLOAD_DIR"

    curl --tlsv1.3 -fsSL --retry 3 \
        -o "$STAGE3_INFO_FILE" "$STAGE3_INFO_URL"

    success "Stage 3 metadata downloaded."
}

import_release_keys() {
    info "Importing Gentoo release signing keys..."

    require_file "/usr/share/openpgp-keys/gentoo-release.asc"

    gpg --import /usr/share/openpgp-keys/gentoo-release.asc

    success "Gentoo release keys imported."
}

verify_stage3_info() {
    info "Verifying Stage 3 metadata..."

    gpg --verify "$STAGE3_INFO_FILE"

    success "Stage 3 metadata verified."
}

get_stage3_path() {
    STAGE_PATH=$(awk \
        -v profile="stage3-${STAGE3_NAME}" \
        'index($1, profile) && $1 ~ /\.tar\.xz$/ {
            print $1
            exit
        }' "$STAGE3_INFO_FILE")

    [[ -n "$STAGE_PATH" ]] || {
        error "Unable to determine the latest Stage 3 archive."
        exit 1
    }

    [[ "$STAGE_PATH" != /* && "$STAGE_PATH" != *"/../"* ]] || {
        error "Invalid Stage 3 archive path."
        exit 1
    }

    STAGE_URL="${STAGE3_BASE_URL}/${STAGE_PATH}"
    STAGE_FILE="${STAGE_PATH##*/}"

    STAGE_CHECKSUM_FILE="${STAGE_FILE}.sha256"
    STAGE_CHECKSUM_VERIFIED="${STAGE_CHECKSUM_FILE}.verified"

    info "Latest Stage 3: $STAGE_FILE"
}

download_stage3() {
    info "Downloading Gentoo Stage 3..."

    curl --tlsv1.3 -fsSL --retry 3 \
        -o "$DOWNLOAD_DIR/$STAGE_FILE" "$STAGE_URL"

    curl --tlsv1.3 -fsSL --retry 3 \
        -o "$DOWNLOAD_DIR/$STAGE_FILE.asc" "${STAGE_URL}.asc"

    curl --tlsv1.3 -fsSL --retry 3 \
        -o "$DOWNLOAD_DIR/$STAGE_CHECKSUM_FILE" \
        "${STAGE_URL}.sha256"

    success "Stage 3 files downloaded."
}

verify_stage3_signature() {
    info "Verifying Stage 3 archive signature..."

    gpg --verify \
        "$DOWNLOAD_DIR/$STAGE_FILE.asc" \
        "$DOWNLOAD_DIR/$STAGE_FILE"

    success "Stage 3 archive signature verified."
}

verify_stage3_checksum() {
    info "Verifying signed SHA256 checksum..."

    gpg --output "$DOWNLOAD_DIR/$STAGE_CHECKSUM_VERIFIED" \
        --verify "$DOWNLOAD_DIR/$STAGE_CHECKSUM_FILE"

    info "Checking Stage 3 SHA256 checksum..."

    (
        cd "$DOWNLOAD_DIR"
        sha256sum --check --strict "$STAGE_CHECKSUM_VERIFIED"
    )

    success "Stage 3 checksum verified."
}

# ------------------------------------------------------------
# Stage 3 extraction
# ------------------------------------------------------------

ensure_target_empty() {
    local existing

    existing=$(find "$MOUNT_POINT" \
        -mindepth 1 -maxdepth 1 \
        ! -name efi \
        ! -name home \
        ! -name lost+found \
        -print -quit)

    [[ -z "$existing" ]] || {
        error "Target root is not empty."
        error "Refusing to extract Stage 3 over existing files."
        exit 1
    }
}

extract_stage3() {
    info "Extracting Stage 3..."

    tar xpvf "$DOWNLOAD_DIR/$STAGE_FILE" \
        --xattrs-include='*.*' \
        --numeric-owner \
        -C "$MOUNT_POINT"

    success "Stage 3 extracted."
}

# ------------------------------------------------------------
# Portage configuration
# ------------------------------------------------------------

calculate_makeopts() {
    local ram_gib
    local jobs

    ram_gib=$(awk \
        '/MemTotal/ {printf "%d\n", $2 / 1024 / 1024}' \
        /proc/meminfo)

    jobs=$(( (ram_gib - 2) / 2 ))
    (( jobs < 1 )) && jobs=1

    MAKEOPTS="-j${jobs}"

    info "Detected RAM: ${ram_gib} GiB"
    info "Using MAKEOPTS: ${MAKEOPTS}"
}

configure_make_conf() {
    local make_conf="$MOUNT_POINT/etc/portage/make.conf"

    info "Configuring make.conf..."

    require_file "$make_conf"

    grep -Fqx 'COMMON_FLAGS="-O2 -pipe"' "$make_conf" ||
        grep -Fqx 'COMMON_FLAGS="-O2 -pipe -march=x86-64-v3"' "$make_conf" || {
            error "Unexpected COMMON_FLAGS configuration."
            exit 1
        }

    sed -i \
        's|^COMMON_FLAGS="-O2 -pipe"$|COMMON_FLAGS="-O2 -pipe -march=x86-64-v3"|' \
        "$make_conf"

    sed -i \
        '/^# Gentoo installer custom configuration$/,$d' \
        "$make_conf"

    cat >> "$make_conf" <<EOF

# Gentoo installer custom configuration
ACCEPT_LICENSE="-* @FREE"
FEATURES="getbinpkg binpkg-request-signature"
USE="dist-kernel"
SELINUX_POLICY_TYPES="mcs"
MAKEOPTS="$MAKEOPTS"
EOF

    success "make.conf configured."
}

# ------------------------------------------------------------
# Stage 3 installation
# ------------------------------------------------------------

install_stage3() {
    require_mount "$MOUNT_POINT"

    if [[ -f "$STAGE3_MARKER" ]]; then
        info "Stage 3 is already installed."
        return
    fi

    require_command curl
    require_command gpg
    require_command awk
    require_command sha256sum
    require_command tar
    require_command find

    fetch_stage3_info
    import_release_keys
    verify_stage3_info
    get_stage3_path
    download_stage3
    verify_stage3_signature
    verify_stage3_checksum

    ensure_target_empty
    extract_stage3

    calculate_makeopts
    configure_make_conf

    touch "$STAGE3_MARKER"

    echo
    success "Gentoo Stage 3 installation complete."
}

