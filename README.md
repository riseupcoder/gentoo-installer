# Gentoo Installer

An automated Gentoo Linux installer for AMD64 systems.

## Description

Installing Gentoo from the handbook is great for learning, but you only
want to do it once. This script handles the whole thing — partitioning,
Stage 3, kernel, networking, the lot — so you can skip straight to a
bootable system.

It uses the official binary package repository, so most packages are
prebuilt and you're not watching a compile for three hours.

## Features

- **OpenRC** — clean init, no systemd bloat
- **Binary-first package installation** — only compiles from source when a binary is unavailable
- **x86-64-v3 optimized binaries** — uses the `-march=x86-64-v3` binhost variant
  for better performance on modern CPUs
- **EFI stub boot** — boots directly via the kernel's EFI stub + dracut;
  no GRUB, no systemd-boot
- **opendoas** — lightweight privilege escalation instead of sudo
- **Fully automated** — one command from LiveCD to a bootable system
- **PGP + SHA256 verification** on Stage 3 and all binary packages

## Prerequisites

- AMD64 system
- Gentoo AMD64 Minimal Installation CD (OpenRC)
- Internet connection
- A dedicated disk for the installation

> [!WARNING]
> The selected installation disk will be completely erased. Make sure any important data is backed up before running the installer.

## How to Run

Boot the official Gentoo AMD64 LiveCD and clone the repository:

```bash
git clone https://github.com/riseupcoder/gentoo-installer
cd gentoo-installer
./install.sh
```
Grab a coffee — you'll come back to a bootable system.
