#!/bin/bash
set +H
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "${SCRIPT_DIR}" && GIT_DIR=$(git rev-parse --show-toplevel)
source "${GIT_DIR}/scripts/GLOBAL_IMPORTS.sh"
source "${GIT_DIR}/configs/settings.sh"

_pkgs_aur_add() {
	[[ -n ${PKGS_AUR} ]] &&
		# -Sdd bypasses a dependency cycle problem proprietary NVIDIA drivers have (only if a different proprietary version is installed such as 'nvidia-lts')
		sudo -H -u "${YOUR_USER}" bash -c "paru -Sdd --quiet --noconfirm --useask --needed --skipreview ${PKGS_AUR[*]}"
}

NvidiaGPUSetup() {
	PKGS+=(xorg-server-devel nvidia-prime \
	nvidia-dkms egl-wayland nvidia-utils opencl-nvidia libxnvctrl nvidia-settings \
  				lib32-nvidia-utils lib32-opencl-nvidia)
	# VDPAU -> VA-API translation layer, mainly for 'mpv' and 'Firefox'.
  	PKGS_AUR+=(libva-nvidia-driver)

	_move2bkup "/etc/modprobe.d/nvidia.conf" &&
		\cp "${cp_flags}" "${GIT_DIR}"/files/etc/modprobe.d/nvidia.conf "/etc/modprobe.d/"

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

	NvidiaForceMaxSpeed() {
		if [[ ${nvidia_force_max_performance} -eq 1 ]]; then
			sudo -H -u "${YOUR_USER}" bash -c "\cp ${cp_flags} ${GIT_DIR}/files/home/.config/systemd/user/nvidia-max-performance.service /home/${YOUR_USER}/.config/systemd/user/"
			sudo -H -u "${YOUR_USER}" bash -c "systemctl --user enable nvidia-max-performance.service"

			# Allow the "Prefer Maximum Performance" PowerMizer setting on laptops
			local KERNEL_PARAMS="nvidia.NVreg_RegistryDwords=OverrideMaxPerf=0x1"
			_modify_kernel_parameters
		fi
	}
	NvidiaForceMaxSpeed

	NvidiaAfterInstall() {
		# Allow adjusting: clock speed, power, and fan control.
		nvidia-xconfig --cool-bits=28
		REGENERATE_INITRAMFS=1
	}
	trap NvidiaAfterInstall EXIT
}

NvidiaGPUSetup
_pkgs_add
_pkgs_aur_add

systemctl enable nvidia-suspend.service nvidia-hibernate.service nvidia-resume.service

if [[ ${IS_CHROOT} -eq 0 ]] && [[ ${REGENERATE_INITRAMFS} -eq 1 ]]; then
	mkinitcpio -P
fi

cleanup() {
	mkdir "${mkdir_flags}" "${BACKUPS}/etc/modprobe.d"
	chown -R "${YOUR_USER}:${YOUR_USER}" "${BACKUPS}/etc/modprobe.d"
}
trap cleanup EXIT
