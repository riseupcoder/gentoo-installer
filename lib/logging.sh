#!/usr/bin/env bash

set -euo pipefail

info() {
    printf '[INFO] %s\n' "$*"
}

success() {
    printf '[ OK ] %s\n' "$*"
}

warn() {
    printf '[WARN] %s\n' "$*" >&2
}

error() {
    printf '[ERROR] %s\n' "$*" >&2
}
