#!/bin/bash
set +H
set -e

SRC_DIR=$(dirname "$(realpath -s "${BASH_SOURCE[0]}")")
source "${SRC_DIR}/GLOBAL_IMPORTS.sh"
source "${SRC_DIR}/Configs/settings.sh"

_pkgs_aur_add() {
	[[ -n ${PKGS_AUR} ]] &&
		# -Sdd bypasses a dependency cycle problem proprietary NVIDIA drivers have (only if a different proprietary version is installed such as 'nvidia-lts')
		sudo -H -u "${YOUR_USER}" bash -c "paru -Sdd --quiet --noconfirm --useask --needed --skipreview ${PKGS_AUR[*]}"
}

NvidiaGPUSetup() {
	# libva-nvidia-driver:
	# - VDPAU -> VA-API translation layer, mainly for GPU acceleration in 'mpv' and 'Firefox'.
	PKGS+=(xorg-server-devel nvidia-prime
	nvidia egl-wayland nvidia-utils opencl-nvidia libxnvctrl nvidia-settings
  		lib32-nvidia-utils lib32-opencl-nvidia libva-nvidia-driver)

	_move2bkup "/etc/modprobe.d/nvidia.conf" &&
		\cp "${cp_flags}" "${SRC_DIR}/Files/etc/modprobe.d/nvidia.conf" "/etc/modprobe.d/"

	[[ ${nvidia_stream_memory_operations} -eq 1 ]] &&
		sed -i "s/NVreg_EnableStreamMemOPs=0/NVreg_EnableStreamMemOPs=1/" /etc/modprobe.d/nvidia.conf

	NvidiaEnableDRM() {
		local KERNEL_PARAMS="nvidia-drm.modeset=1"
		_modify_kernel_parameters

		if ! grep -q "MODULES+=(nvidia nvidia_modeset nvidia_uvm nvidia_drm)" /etc/mkinitcpio.conf; then
			echo "MODULES+=(nvidia nvidia_modeset nvidia_uvm nvidia_drm)" >>/etc/mkinitcpio.conf
		fi
	}
	NvidiaEnableDRM

	NvidiaAfterInstall() {
		# Allow adjusting: clock speed, power, and fan control.
		nvidia-xconfig --cool-bits=28
	}
	trap NvidiaAfterInstall EXIT
}

NvidiaGPUSetup
_pkgs_add
_pkgs_aur_add

systemctl enable nvidia-suspend.service nvidia-hibernate.service nvidia-resume.service

cleanup() {
	mkdir "${mkdir_flags}" "${BACKUPS}/etc/modprobe.d"
	chown -R "${YOUR_USER}:${YOUR_USER}" "${BACKUPS}/etc/modprobe.d"
}
trap cleanup EXIT
