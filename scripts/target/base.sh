#!/usr/bin/env bash

set -euo pipefail

# ============================================================
# Gentoo Base System
# ============================================================

# Update repository
emerge-webrsync

# Configure binary package repository
mkdir -p /etc/portage/binrepos.conf

cat > /etc/portage/binrepos.conf/gentoo.conf <<'EOF'
[gentoo-x86-64-v3]
priority = 9999
sync-uri = https://distfiles.gentoo.org/releases/amd64/binpackages/23.0/x86-64-v3/
verify-signature = true
location = /var/cache/binhost/gentoo-x86-64-v3
EOF

# Initialize binary package verification
getuto

# Update world
emerge --verbose --update --deep --changed-use --getbinpkg @world

# Timezone
ln -sf ../usr/share/zoneinfo/UTC /etc/localtime

# Locale
grep -qxF 'en_US.UTF-8 UTF-8' /etc/locale.gen ||
    printf '%s\n' 'en_US.UTF-8 UTF-8' >> /etc/locale.gen

locale-gen

printf 'LANG="en_US.UTF-8"\n' > /etc/env.d/02locale

# Update environment
env-update
source /etc/profile
