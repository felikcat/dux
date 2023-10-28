#!/bin/bash
# shellcheck disable=SC2034
set +H
set -e

SRC_DIR=$(dirname "$(realpath -s "${BASH_SOURCE[0]}")")
source "${SRC_DIR}/GLOBAL_IMPORTS.sh"
source "${SRC_DIR}/Configs/settings.sh"

clear

# Now is the right time to generate a initramfs.
pacman -S --quiet --noconfirm --ask=4 --overwrite="*" mkinitcpio
\cp "${cp_flags}" "${SRC_DIR}/Files/etc/mkinitcpio.conf" "/etc/"

# Installing these late sped up the install process prior.
PKGS+=(linux linux-headers snapper snap-pac)
_pkgs_add

if lspci | grep -P "VGA|3D|Display" | grep -q "NVIDIA"; then
	(bash "${SRC_DIR}/_NVIDIA.sh") |& tee "${SRC_DIR}/logs/_NVIDIA.log" || return
fi

SetupSnapper() {
	(bash "${SRC_DIR}/snapper.sh") |& tee "${SRC_DIR}/logs/snapper.log"
}
SetupSnapper

grub-mkconfig -o /boot/grub/grub.cfg

Cleanup() {
	# Permit users in group 'wheel' to request privilege escalation through sudo.
    echo "%wheel ALL=(ALL) ALL" >/etc/sudoers.d/custom_settings
}
trap Cleanup EXIT
