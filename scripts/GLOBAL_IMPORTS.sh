#!/bin/bash
# shellcheck disable=SC2034
set +H
set -e

[[ ${KEEP_GOING} -eq 1 ]] &&
	set +e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# SCRIPT_DIR is used to make GIT_DIR reliable
cd "${SCRIPT_DIR}" && GIT_DIR=$(git rev-parse --show-toplevel)
source "${GIT_DIR}/configs/settings.sh"

# DEBUG=1 bash ~/dux/scripts/example.sh
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

BOOT_CONF="/boot/refind_linux.conf" && export BOOT_CONF

[[ -z ${SYSTEMD_USER_ENV:-} ]] &&
	SYSTEMD_USER_ENV="DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/1000/bus XDG_RUNTIME_DIR=/run/user/1000" &&
	export SYSTEMD_USER_ENV

if systemd-detect-virt --chroot >&/dev/null; then
	IS_CHROOT=1
fi

BACKUPS="/home/${INITIAL_USER}/dux_backups" && export BACKUPS

_flatpaks_add() {
	# shellcheck disable=SC2048
	[[ -n ${FLATPAKS} ]] &&
		flatpak install --noninteractive flathub ${FLATPAKS[*]}
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
	[[ -n ${PKGS_AUR} ]] &&
		# Use -Syu instead of -Syuu for paru.
		# NoProgressBar: the TTY framebuffer is likely not GPU accelerated while booted into the Arch Linux ISO; render less text = Dux installs faster.
		sudo -H -u "${INITIAL_USER}" bash -c "${SYSTEMD_USER_ENV} DENY_SUPERUSER=1 paru -Syu --aur --quiet --noprogressbar --noconfirm --useask --needed --skipreview ${PKGS_AUR[*]}"
}

if [[ ${DENY_SUPERUSER:-} -eq 1 && $(id -u) -ne 1000 ]]; then
	echo -e "\e[1m\nNormal privileges required; don't use sudo or doas!\e[0m\nCurrently affected scripts: \"${BASH_SOURCE[*]}\"\n" >&2
	exit 1
fi

if [[ ${DENY_SUPERUSER:-} -ne 1 && $(id -u) -ne 0 ]]; then
	echo -e "\e[1m\nSuperuser required, prompting if needed...\e[0m\nCurrently affected scripts: \"${BASH_SOURCE[*]}\"\n" >&2
	if hash sudo >&/dev/null; then
		sudo bash "${0}"
		exit $?
	elif hash doas >&/dev/null; then
		doas bash "${0}"
		exit $?
	fi
fi

# Functions requiring superuser
if [[ ${DENY_SUPERUSER:-} -ne 1 && $(id -u) -eq 0 ]]; then
	_pkgs_add() {
		[[ -n ${PKGS} ]] &&
			sudo pacman -Syu --quiet --noprogressbar --noconfirm --ask=4 --needed "${PKGS[@]}"
	}
	_modify_kernel_parameters() {
		if ! grep -q "${KERNEL_PARAMS}" "${BOOT_CONF}"; then
            sed -i -e "s/standard options\"[ ]*\"[^\"]*/& ${KERNEL_PARAMS}/" \
                -e "s/user mode\"[ ]*\"[^\"]*/& ${KERNEL_PARAMS}/" "${BOOT_CONF}"
		fi
	}
fi
