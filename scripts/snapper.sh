#!/bin/bash
set +H
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "${SCRIPT_DIR}" && GIT_DIR=$(git rev-parse --show-toplevel)
source "${GIT_DIR}/scripts/GLOBAL_IMPORTS.sh"
source "${GIT_DIR}/configs/settings.sh"

clear

# The developer of python-pid might let their PGP key expire again.
gpg --recv-keys 13FFEEE3DF809D320053C587D6E95F20305701A1

PKGS_AUR+="refind-btrfs "
_pkgs_aur_add

# If /.snapshots already exists, snapper will fail to create its config.
snapper --no-dbus create-config / || :
\cp "${cp_flags}" "${GIT_DIR}"/files/etc/snapper/configs/root "/etc/snapper/configs/"

SERVICES+=(refind-btrfs.service snapper-boot.timer snapper-cleanup.timer snapper-timeline.timer)
systemctl enable "${SERVICES[@]}"
