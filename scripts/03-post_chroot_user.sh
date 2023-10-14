#!/bin/bash
set +H
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "${SCRIPT_DIR}" && GIT_DIR=$(git rev-parse --show-toplevel)
source "${GIT_DIR}/scripts/GLOBAL_IMPORTS.sh"
source "${GIT_DIR}/configs/settings.sh"

clear

# Install Paru, an AUR helper.
if ! hash paru >&/dev/null; then
	[[ -d "/home/${YOUR_USER}/paru-bin" ]] &&
		trash-put -rf /home/"${YOUR_USER}"/paru-bin

	git clone https://aur.archlinux.org/paru-bin.git /home/"${YOUR_USER}"/paru-bin
	cd /home/"${YOUR_USER}"/paru-bin
	makepkg -si --noconfirm
fi

SetupOtherUserFiles() {
	if ! grep -q 'add-zsh-hook' "/home/${YOUR_USER}/.zshrc" >&/dev/null; then
		cat "${GIT_DIR}/files/home/.zshrc" >>"/home/${YOUR_USER}/.zshrc"
	fi
}

PKGS_AUR+=(btrfs-assistant)
_pkgs_aur_add
SetupOtherUserFiles

mkdir "${mkdir_flags}" /home/"${YOUR_USER}"/.config/environment.d
\cp "${cp_flags}" "${GIT_DIR}"/files/home/.config/environment.d/dxvk.conf "/home/${YOUR_USER}/.config/environment.d/"
