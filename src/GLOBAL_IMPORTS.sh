#!/bin/bash
# shellcheck disable=SC2034
set +H
set -e

[[ ${KEEP_GOING} -eq 1 ]] &&
	set +e

SRC_DIR=$(dirname "$(realpath -s "${BASH_SOURCE[0]}")")
source "${SRC_DIR}/Configs/settings.sh"

# DEBUG=1 bash ~/dux/src/example.sh
if [[ ${DEBUG} -eq 1 ]]; then
	set -x
	cp_flags="-fv"
	mkdir_flags="-pv"
	mv_flags="-fv"
else
	cp_flags="-f"
	mkdir_flags="-p"
	mv_flags="-f"
fi

[[ -z ${DATE:-} ]] &&
	DATE=$(date +"%d-%m-%Y_%H-%M-%S") && export DATE

BOOT_CONF="/etc/default/grub" && export BOOT_CONF

[[ -z ${SYSTEMD_USER_ENV:-} ]] &&
	SYSTEMD_USER_ENV="DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/1000/bus XDG_RUNTIME_DIR=/run/user/1000" &&
	export SYSTEMD_USER_ENV

if systemd-detect-virt --chroot >&/dev/null; then
	IS_CHROOT=1
fi

BACKUPS="/home/${YOUR_USER}/dux_backups" && export BACKUPS

_flatpaks_add() {
	# shellcheck disable=SC2048
	if [[ -n ${FLATPAKS} ]]; then
		flatpak install --noninteractive flathub ${FLATPAKS[*]} || :
	fi
}

_move2bkup() {
	local target
	for target in "$@"; do
		if [[ -f ${target} ]]; then
			local parent_dir
			parent_dir=$(dirname "${target}")
			mkdir "${mkdir_flags}" ${BACKUPS}${parent_dir}
			mv "${mv_flags}" "${target}" "${BACKUPS}${target}_${DATE}" || :

		elif [[ -d ${target} ]]; then
			mv "${mv_flags}" "${target}" "${BACKUPS}${target}_${DATE}" || :
		fi
	done
}

_pkgs_aur_add() {
	if [[ -n ${PKGS_AUR} ]]; then
		# Use -Syu instead of -Syuu for paru.
		# NoProgressBar: the TTY framebuffer is likely not GPU accelerated while booted into the Arch Linux ISO; render less text = Dux installs faster.
		sudo -H -u "${YOUR_USER}" bash -c "paru -Syu --aur --quiet --noprogressbar --noconfirm --useask --needed --skipreview ${PKGS_AUR[*]}" || :
	fi
}

# Functions requiring superuser
_pkgs_add() {
	if [[ -n ${PKGS} ]]; then
		sudo pacman -Syu --quiet --noprogressbar --noconfirm --ask=4 --needed "${PKGS[@]}" || :
	fi
}

_modify_kernel_parameters() {
	if ! grep -q "${KERNEL_PARAMS}" "${BOOT_CONF}"; then
		sed -i "s/GRUB_CMDLINE_LINUX_DEFAULT=\"[^\"]*/& ${PARAMS}/" "${BOOT_CONF}"
				REGENERATE_GRUB2_CONFIG=1
	fi
}

