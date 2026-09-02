#!/usr/bin/env bash

readonly CONFIG_DIR="$ROOT_DIR/config"
readonly SCRIPTS_DIR="$ROOT_DIR/scripts"
readonly LIB_DIR="$ROOT_DIR/lib"

chroot_run() {
    arch-chroot "$MOUNT_POINT" /bin/bash -c "$1"
}
