#!/bin/bash
set +H
set -e

SRC_DIR="$(realpath .)"
source "${SRC_DIR}/GLOBAL_IMPORTS.sh"
source "${SRC_DIR}/Configs/settings.sh"

clear

# FOR REFIND -> if [[ ${bootloader_chosen} -eq 2 ]]; then
    # The developer of python-pid might let their PGP key expire again.
    gpg --recv-keys 13FFEEE3DF809D320053C587D6E95F20305701A1

    PKGS_AUR+=(refind-btrfs)
    _pkgs_aur_add

    SERVICES+=(refind-btrfs.service snapper-boot.timer snapper-cleanup.timer snapper-timeline.timer)
    systemctl enable "${SERVICES[@]}"
#fi

# If /.snapshots already exists, snapper will fail to create its config.
snapper --no-dbus create-config / || :
\cp "${cp_flags}" "${SRC_DIR}"/Files/etc/snapper/configs/root "/etc/snapper/configs/"
