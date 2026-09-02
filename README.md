# Gentoo Installer

An automated Gentoo Linux installer for AMD64 systems.

## Description

Installing Gentoo by following the Gentoo Handbook is an excellent way to learn how Linux works under the hood. But going through the entire handbook every single time you need to install a system is tedious and time-consuming. That's why I built this script it automates the repetitive parts of the installation: partitioning, Stage 3 setup, kernel configuration, networking, and everything in between. 

I also noticed that many people find the Gentoo installation process intimidating, especially as beginners. My hope is that this script lowers that barrier, so you can try Gentoo without the fear of getting lost in a lengthy handbook. If you're new to Linux, I'd still recommend reading through the Gentoo Handbook at least once when you have the time it's one of the best ways to understand why each step exists. 

The script is intentionally kept simple and readable, so you can verify what it's doing before you run it, rather than just taking someone's word for it. There are many valid ways to install Gentoo. This script simply reflects my personal preferences. Feel free to customize it to suit your own needs.

## Features

- OpenRC — clean init, no systemd
- Binary-first package installation — only compiles from source when a binary is unavailable
- x86-64-v3 optimized binaries — better performance on modern CPUs
- EFI stub boot — boots directly via the kernel's EFI stub + dracut; no GRUB, no systemd-boot
- opendoas — lightweight privilege escalation instead of sudo
- Fully automated — one command to a fully working Gentoo system.

## Prerequisites

- An AMD64 (x86_64) system
- Gentoo AMD64 Minimal Installation ISO (OpenRC)
- Internet connection
- A dedicated disk (or partition) for the installation

## How to Run

Boot the Gentoo AMD64 Minimal ISO, then:

```bash
git clone https://github.com/riseupcoder/gentoo-installer.git
cd gentoo-installer
./install.sh
```
Grab a coffee you'll come back to a bootable system.
