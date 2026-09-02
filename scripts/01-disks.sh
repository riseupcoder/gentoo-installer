#!/usr/bin/env bash

set -euo pipefail

# ============================================================
# Gentoo Disk Preparation
#
# Layout:
#   EFI  = 1 GiB
#   ROOT = 30 GiB
#   HOME = remaining space
# ============================================================

select_disk() {

    info "Available disks:"
    echo

    lsblk -d -o NAME,SIZE,MODEL,TYPE

    echo
    read -rp \
        "Enter installation disk (e.g. /dev/sda or /dev/nvme0n1): " \
        DISK
}

validate_disk() {

    info "Validating installation disk..."

    if [[ ! -b "$DISK" ]]; then
        error "'$DISK' is not a valid block device."
        exit 1
    fi

    if [[ "$(lsblk -dnro TYPE "$DISK")" != "disk" ]]; then
        error "'$DISK' is not a whole disk."
        exit 1
    fi

    if lsblk -nrpo MOUNTPOINT "$DISK" | grep -q .; then
        error "The selected disk has mounted filesystems."
        error "Unmount them before continuing."
        exit 1
    fi

    success "Installation disk validated."
}

confirm_disk() {

    echo
    info "Selected disk:"
    echo

    lsblk "$DISK"

    echo
    warn "ALL DATA on $DISK will be erased."
    echo

    read -rp \
        "Continue? Type 'yes' to continue: " \
        CONFIRM

    if [[ "$CONFIRM" != "yes" ]]; then
        info "Aborted."
        exit 0
    fi
}

create_partitions() {

    local EFI_SIZE="1GiB"
    local ROOT_SIZE="30GiB"

    info "Creating GPT partition table..."

    if ! sfdisk "$DISK" <<EOF
label: gpt
size=$EFI_SIZE, type=U
size=$ROOT_SIZE, type=linux
type=linux
EOF
    then
        error "Failed to create GPT partition table."
        exit 1
    fi

    success "GPT partition table created."
}

detect_partitions() {

    info "Detecting created partitions..."

    mapfile -t PARTITIONS < <(
        lsblk -lnpo NAME,TYPE "$DISK" |
        awk '$2 == "part" {print $1}'
    )

    if [[ "${#PARTITIONS[@]}" -ne 3 ]]; then
        error "Expected 3 partitions, found ${#PARTITIONS[@]}."
        exit 1
    fi

    EFI_PARTITION="${PARTITIONS[0]}"
    ROOT_PARTITION="${PARTITIONS[1]}"
    HOME_PARTITION="${PARTITIONS[2]}"

    success "Partitions detected."

    printf ' EFI : %s\n' "$EFI_PARTITION"
    printf ' ROOT: %s\n' "$ROOT_PARTITION"
    printf ' HOME: %s\n' "$HOME_PARTITION"
}

create_filesystems() {

    info "Formatting EFI partition..."

    if ! mkfs.vfat -F 32 "$EFI_PARTITION"; then
        error "Failed to format EFI partition."
        exit 1
    fi

    success "EFI filesystem created."

    info "Formatting root partition..."

    if ! mkfs.ext4 "$ROOT_PARTITION"; then
        error "Failed to format root partition."
        exit 1
    fi

    success "Root filesystem created."

    info "Formatting home partition..."

    if ! mkfs.ext4 "$HOME_PARTITION"; then
        error "Failed to format home partition."
        exit 1
    fi

    success "Home filesystem created."
}

mount_filesystems() {

    info "Creating EFI mount point..."

    if ! mkdir -p "$MOUNT_POINT/efi"; then
        error "Failed to create EFI mount point."
        exit 1
    fi

    info "Mounting root filesystem..."

    if ! mount "$ROOT_PARTITION" "$MOUNT_POINT"; then
        error "Failed to mount root filesystem."
        exit 1
    fi

    info "Mounting EFI filesystem..."
    
    echo "mount point location - $MOUNT_POINT"
    echo "found efi partition - $EFI_PARTITION"
    echo "ls -l $MOUNT_POINT"
    echo "ls -l $MOUNT_POINT/efi"
    
    mkdir -p /mnt/gentoo/efi

    if ! mount "$EFI_PARTITION" "$MOUNT_POINT/efi"; then
        error "Failed to mount EFI filesystem."
        exit 1
    fi

    success "Root and EFI filesystems mounted."
}


verify_disk() {

    echo
    success "Disk preparation complete."

    echo
    lsblk "$DISK"
}


prepare_disk() {

    select_disk
    validate_disk
    confirm_disk
    create_partitions
    detect_partitions
    create_filesystems
    mount_filesystems
    verify_disk
}

