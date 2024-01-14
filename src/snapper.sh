#!/bin/bash
set +H
set -e

SRC_DIR=$(dirname "$(realpath -s "$(dirname "$0")")")
source "${SRC_DIR}/GLOBAL_IMPORTS.sh"
source "${SRC_DIR}/Configs/settings.sh"

clear

PKGS+=(snapper snap-pac grub-btrfs)
_pkgs_add

# If /.snapshots already exists, snapper will fail to create its config.
snapper --no-dbus create-config / || :
\cp "${cp_flags}" "${SRC_DIR}"/Files/etc/snapper/configs/root "/etc/snapper/configs/"

SERVICES+=(grub-btrfsd.service snapper-boot.timer snapper-cleanup.timer snapper-timeline.timer)
systemctl enable "${SERVICES[@]}"
