#!/bin/bash
set +H
set -e

SRC_DIR=$(dirname "$(realpath -s "${BASH_SOURCE[0]}")")
source "${SRC_DIR}/GLOBAL_IMPORTS.sh"
source "${SRC_DIR}/Configs/settings.sh"

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
		cat "${SRC_DIR}/Files/home/.zshrc" >>"/home/${YOUR_USER}/.zshrc"
	fi
}
SetupOtherUserFiles

mkdir "${mkdir_flags}" "/home/${YOUR_USER}/.config/environment.d"
\cp "${cp_flags}" "${SRC_DIR}/Files/home/.config/environment.d/dxvk.conf" "/home/${YOUR_USER}/.config/environment.d/"
