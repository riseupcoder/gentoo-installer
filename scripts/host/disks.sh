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

readonly EFI_PARTLABEL="GENTOO_EFI"
readonly ROOT_PARTLABEL="GENTOO_ROOT"
readonly HOME_PARTLABEL="GENTOO_HOME"

select_disk() {
    require_command lsblk

    info "Available disks:"
    echo

    lsblk -d -o NAME,SIZE,MODEL,TYPE

    echo
    read -r -p "Enter installation disk: " DISK
}

validate_disk() {
    require_command lsblk

    [[ -b "$DISK" ]] || {
        error "'$DISK' is not a valid block device."
        exit 1
    }

    [[ "$(lsblk -dnro TYPE "$DISK")" == "disk" ]] || {
        error "'$DISK' is not a whole disk."
        exit 1
    }

    success "Installation disk validated."
}

ensure_disk_unmounted() {
    if lsblk -nrpo MOUNTPOINT "$DISK" | grep -q .; then
        error "Selected disk has mounted filesystems."
        error "Unmount them before continuing."
        exit 1
    fi
}

confirm_disk() {
    echo
    info "Selected disk:"
    lsblk "$DISK"

    echo
    warn "ALL DATA on $DISK will be erased."
    echo

    read -r -p "Continue? Type 'yes' to continue: " CONFIRM

    [[ "$CONFIRM" == "yes" ]] || {
        info "Aborted."
        exit 0
    }
}

partition_device() {
    local label="$1"
    local -a partitions

    mapfile -t partitions < <(
        lsblk -nrpo NAME,PARTLABEL "$DISK" |
            awk -v label="$label" '$2 == label {print $1}'
    )

    if [[ "${#partitions[@]}" -ne 1 ]]; then
        error "Expected exactly one partition labelled '$label'."
        exit 1
    fi

    printf '%s\n' "${partitions[0]}"
}

detect_partitions() {
    local disk_name
    local partition

    info "Detecting installation partitions..."

    disk_name=$(lsblk -dnro NAME "$DISK")

    EFI_PARTITION=$(partition_device "$EFI_PARTLABEL")
    ROOT_PARTITION=$(partition_device "$ROOT_PARTLABEL")
    HOME_PARTITION=$(partition_device "$HOME_PARTLABEL")

    for partition in "$EFI_PARTITION" "$ROOT_PARTITION" "$HOME_PARTITION"; do
        if [[ "$(lsblk -dnro PKNAME "$partition")" != "$disk_name" ]]; then
            error "Partition $partition does not belong to $DISK."
            exit 1
        fi
    done

    printf ' EFI : %s\n' "$EFI_PARTITION"
    printf ' ROOT: %s\n' "$ROOT_PARTITION"
    printf ' HOME: %s\n' "$HOME_PARTITION"

    success "Partitions detected."
}

create_partitions() {
    info "Creating GPT partition table..."

    sfdisk "$DISK" <<EOF
label: gpt
size=1GiB, type=U, name="$EFI_PARTLABEL"
size=30GiB, type=linux, name="$ROOT_PARTLABEL"
type=linux, name="$HOME_PARTLABEL"
EOF

    udevadm settle

    success "GPT partition table created."
}

create_filesystems() {
    info "Creating EFI filesystem..."
    mkfs.vfat -F 32 -n "$EFI_PARTLABEL" "$EFI_PARTITION"

    info "Creating root filesystem..."
    mkfs.ext4 -L "$ROOT_PARTLABEL" "$ROOT_PARTITION"

    info "Creating home filesystem..."
    mkfs.ext4 -L "$HOME_PARTLABEL" "$HOME_PARTITION"

    success "Filesystems created."
}

mount_partition() {
    local partition="$1"
    local mountpoint="$2"
    local mounted_source

    if mounted_source=$(findmnt -rn -M "$mountpoint" -o SOURCE); then
        [[ "$(readlink -f -- "$mounted_source")" == \
           "$(readlink -f -- "$partition")" ]] || {
            error "Unexpected filesystem mounted at $mountpoint."
            error "Expected: $partition"
            error "Found: $mounted_source"
            exit 1
        }

        info "$mountpoint is already mounted correctly."
        return
    fi

    mkdir -p "$mountpoint"
    mount "$partition" "$mountpoint"

    success "Mounted $partition at $mountpoint."
}

mount_target_filesystems() {
    [[ -n "${DISK:-}" ]] || select_disk

    validate_disk
    detect_partitions

    mount_partition "$ROOT_PARTITION" "$MOUNT_POINT"
    mount_partition "$EFI_PARTITION" "$MOUNT_POINT/efi"
    mount_partition "$HOME_PARTITION" "$MOUNT_POINT/home"

    echo
    success "Target filesystems mounted."

    findmnt -R "$MOUNT_POINT"
}

prepare_disk() {
    select_disk
    validate_disk
    ensure_disk_unmounted
    confirm_disk

    create_partitions
    detect_partitions
    create_filesystems

    echo
    success "Disk preparation complete."
}
