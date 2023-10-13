#!/bin/bash
# shellcheck disable=SC2034
set +H
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "${SCRIPT_DIR}" && GIT_DIR=$(git rev-parse --show-toplevel)
source "${GIT_DIR}/scripts/GLOBAL_IMPORTS.sh"
source "${GIT_DIR}/configs/settings.sh"

clear

# Now is the right time to generate a initramfs.
pacman -S --quiet --noconfirm --ask=4 --overwrite="*" mkinitcpio
\cp "${cp_flags}" "${GIT_DIR}"/files/etc/mkinitcpio.conf "/etc/"

# Installing these late sped up the install process prior.
PKGS+=(linux linux-headers snapper snap-pac)
_pkgs_add || :

if lspci | grep -P "VGA|3D|Display" | grep -q "NVIDIA"; then
	(bash "${GIT_DIR}/scripts/_NVIDIA.sh") |& tee "${GIT_DIR}/logs/_NVIDIA.log" || return
fi

SetupSnapper() {
	(bash "${GIT_DIR}/scripts/snapper.sh") |& tee "${GIT_DIR}/logs/snapper.log"
}
SetupSnapper

# Without this, Dux breaks if ran by a different user (such as root) in the home directory.
git config --global --add safe.directory /home/"${YOUR_USER}"/dux
git config --global --add safe.directory /root/dux

Cleanup() {
	# Permit users in group 'wheel' to request privilege escalation through sudo.
    echo "%wheel ALL=(ALL) ALL" >/etc/sudoers.d/custom_settings
}
trap Cleanup EXIT
