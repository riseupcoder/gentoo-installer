#!/usr/bin/env bash

set -euo pipefail

# ============================================================
# Gentoo Kernel Configuration
# ============================================================

install_firmware() {

    info "Installing Linux firmware..."

    mkdir -p /etc/portage/package.mask /etc/portage/package.use

    echo "sys-kernel/linux-firmware linux-fw-redistributable" >> /etc/portage/package.license

    echo "sys-kernel/gentoo-kernel" > /etc/portage/package.mask/gentoo-kernel

    echo "sys-kernel/linux-firmware -initramfs -dist-kernel" > /etc/portage/package.use/linuxfirmware

    emerge --verbose sys-kernel/linux-firmware

    success "Linux firmware installed."
}

configure_installkernel() {

    info "Configuring installkernel..."

    echo "sys-kernel/installkernel dracut efistub" > /etc/portage/package.use/installkernel

    success "installkernel configured."
}

install_installkernel() {

    info "Installing installkernel..."

    emerge --verbose sys-kernel/installkernel

    success "installkernel installed."
}

create_efi_directory() {

    info "Creating EFI/Gentoo directory..."

    mkdir -p /efi/EFI/Gentoo

    success "EFI/Gentoo directory created."
}

configure_kernel_commandline() {
    local root_uuid="$1"
    local uefi_config="/etc/default/uefi-mkconfig"

    local kernel_options="slab_nomerge init_on_alloc=1 init_on_free=1 page_alloc.shuffle=1 pti=on randomize_kstack_offset=on vsyscall=none debugfs=off oops=panic module.sig_enforce=1 lockdown=confidentiality mce=0 quiet loglevel=0 slub_debug=FZP hardened_usercopy=1 hash_pointers=always iommu.passthrough=0 iommu.strict=1 vdso32=0 cfi=kcfi random.trust_cpu=off random.trust_bootloader=off amd_iommu=on iommu=force rd.shell=0 rd.emergency=halt systemd.ssh_auto=no lsm=selinux selinux=1 enforcing=0 proc_mem.force_override=never ia32_emulation=0 kvm.mitigate_smt_rsb=1 efi=disable_early_pci_dma ipv6.disable=1"

    info "Configuring kernel command line..."

    sed -i '/^KERNEL_CONFIG=/s/^/#/' "$uefi_config"

    echo "KERNEL_CONFIG=\"%entry_id %linux_name Linux %kernel_version ; root=UUID=$root_uuid ro $kernel_options\"" >> "$uefi_config"

    uefi-mkconfig

    success "Kernel command line configured."
}

install_binary_kernel() {

    info "Installing Gentoo binary kernel..."
    mkdir -p /etc/portage/package.accept_keywords

    echo "sys-kernel/gentoo-kernel-bin ~amd64" > /etc/portage/package.accept_keywords/gentoo-kernel-bin
    echo "virtual/dist-kernel ~amd64" > /etc/portage/package.accept_keywords/gentoo-kernel-bin

    emerge --verbose sys-kernel/gentoo-kernel-bin

    success "Gentoo binary kernel installed."
}

install_kernel() {

    local root_uuid="$1"

    configure_installkernel
    install_firmware
    install_installkernel
    create_efi_directory
    install_binary_kernel
    configure_kernel_commandline "$root_uuid"

    echo
    success "Gentoo kernel installation complete."
}

install_kernel "$1"
