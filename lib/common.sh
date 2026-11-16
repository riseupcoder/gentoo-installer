#!/usr/bin/env bash

readonly CONFIG_DIR="$ROOT_DIR/config"
readonly SCRIPTS_DIR="$ROOT_DIR/scripts"
readonly LIB_DIR="$ROOT_DIR/lib"

require_file() {
    [[ -f "$1" ]] || {
        error "Required file not found: $1"
        exit 1
    }
}

require_dir() {
    [[ -d "$1" ]] || {
        error "Required directory not found: $1"
        exit 1
    }
}

require_command() {
    command -v "$1" >/dev/null 2>&1 || {
        error "Required command not found: $1"
        exit 1
    }
}

require_mount() {
    mountpoint -q "$1" || {
        error "Required mountpoint is not mounted: $1"
        exit 1
    }
}

chroot_run() {
    arch-chroot "$MOUNT_POINT" /bin/bash -c "$1"
}

