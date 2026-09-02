#!/usr/bin/env bash

set -euo pipefail

# ============================================================
# Gentoo Kernel Configuration
# ============================================================

install_firmware() {

    info "Installing Linux firmware..."
    
    chroot_run 'echo "sys-kernel/linux-firmware linux-fw-redistributable" >> /etc/portage/package.license'

    chroot_run 'echo "sys-kernel/gentoo-kernel" >> /etc/portage/package.mask/gentoo-kernel'

    chroot_run 'echo "sys-kernel/linux-firmware -initramfs -dist-kernel" >> /etc/portage/package.use/linuxfirmware'
      
    if ! chroot_run 'emerge --verbose sys-kernel/linux-firmware'; then
        error "Failed to install Linux firmware."
        exit 1
    fi

    success "Linux firmware installed."
}

configure_installkernel() {

    local installkernel_use_dir="$MOUNT_POINT/etc/portage/package.use"
    local installkernel_use="$installkernel_use_dir/installkernel"

    info "Configuring installkernel..."

    if ! mkdir -p "$installkernel_use_dir"; then
        error "Failed to create package.use directory."
        exit 1
    fi

    if ! printf '%s\n' \
        'sys-kernel/installkernel dracut efistub' \
        > "$installkernel_use"; then

        error "Failed to configure installkernel."
        exit 1
    fi

    success "installkernel configured."
}

install_installkernel() {

    info "Installing installkernel..."

    if ! chroot_run 'emerge --verbose sys-kernel/installkernel'; then
        error "Failed to install installkernel."
        exit 1
    fi

    success "installkernel installed."
}

create_efi_directory() {

    info "Creating EFI/Gentoo directory..."

    if ! chroot_run 'mkdir -p /efi/EFI/Gentoo'; then
        error "Failed to create EFI/Gentoo directory."
        exit 1
    fi

    success "EFI/Gentoo directory created."
}

configure_kernel_commandline() {

    local uefi_config="/etc/default/uefi-mkconfig"
    local root_uuid

    info "Configuring kernel command line..."

    root_uuid=$(findmnt -no UUID "$MOUNT_POINT")

    if [[ -z "$root_uuid" ]]; then
        error "Failed to determine root filesystem UUID."
        exit 1
    fi

    info "Root filesystem UUID: $root_uuid"

    if ! chroot_run \
        "sed -i '/^KERNEL_CONFIG=/s/^/#/' '$uefi_config'"; then

        error "Failed to disable default KERNEL_CONFIG."
        exit 1
    fi

    if ! chroot_run \
        "printf '%s\n' 'KERNEL_CONFIG=\"%entry_id %linux_name Linux %kernel_version ; root=UUID=$root_uuid ro\"' >> '$uefi_config'"; then

        error "Failed to configure KERNEL_CONFIG."
        exit 1
    fi
    
    chroot_run 'uefi-mkconfig'

    success "Kernel command line configured."
}

install_binary_kernel() {

    info "Installing Gentoo binary kernel..."

    if ! chroot_run 'emerge --verbose sys-kernel/gentoo-kernel-bin'; then
        error "Failed to install Gentoo binary kernel."
        exit 1
    fi

    success "Gentoo binary kernel installed."
}

cleanup_packages() {

    info "Removing unnecessary packages..."

    if ! chroot_run 'emerge --depclean'; then
        error "Failed to perform depclean."
        exit 1
    fi

    success "Unnecessary packages removed."
}

install_kernel() {

    configure_installkernel
    install_firmware
    install_installkernel
    create_efi_directory
    install_binary_kernel
    configure_kernel_commandline
    cleanup_packages

    echo
    success "Gentoo kernel installation complete."
}

