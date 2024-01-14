#!/bin/bash
# shellcheck disable=SC2034
set +H
set -e

SRC_DIR=$(dirname "$(realpath -s "${BASH_SOURCE[0]}")")
source "${SRC_DIR}/GLOBAL_IMPORTS.sh"
source "${SRC_DIR}/Configs/settings.sh"

clear

SetupSnapper() {
	(bash "${SRC_DIR}/snapper.sh") |& tee "${SRC_DIR}/logs/snapper.log"
}
SetupSnapper

# Installing these late sped up the install process prior.
PKGS+=(linux linux-headers)
_pkgs_add

if lspci | grep -P "VGA|3D|Display" | grep -q "NVIDIA"; then
	(bash "${SRC_DIR}/_NVIDIA.sh") |& tee "${SRC_DIR}/logs/_NVIDIA.log" || return
fi

# Generate bootloader entries.
grub-mkconfig -o /boot/grub/grub.cfg

Cleanup() {
	# It's dangerous to allow superuser with no password.
    rm /etc/sudoers.d/custom_settings
}
trap Cleanup EXIT
