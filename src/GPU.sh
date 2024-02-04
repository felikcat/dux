#!/bin/bash
set +H
set -e

SRC_DIR=$(dirname "$(realpath -s "${BASH_SOURCE[0]}")")
source "${SRC_DIR}/GLOBAL_IMPORTS.sh"
source "${SRC_DIR}/Configs/settings.sh"

PKGS+=(lib32-mesa lib32-ocl-icd lib32-vulkan-icd-loader mesa ocl-icd vulkan-icd-loader)

AMDGPUSetup() {
	PKGS+=(vulkan-radeon lib32-vulkan-radeon
	libva-mesa-driver lib32-libva-mesa-driver mesa-vdpau lib32-mesa-vdpau)

	# Early load KMS driver
	if [[ ! -a "/tmp/amdgpu_early_kms.empty" ]]; then
		echo -e "\nMODULES+=(amdgpu)" >>/etc/mkinitcpio.conf
		touch "/tmp/amdgpu_early_kms.empty"
	fi
}

NvidiaGPUSetup() {
	(bash "${SRC_DIR}/_NVIDIA.sh") |& tee "${SRC_DIR}/logs/_NVIDIA.log" || return
}

IntelGPUSetup() {
	PKGS+=(vulkan-intel)

	[[ ${intel_video_accel} -eq 1 ]] &&
		PKGS+=(libva-intel-driver lib32-libva-intel-driver)
	[[ ${intel_video_accel} -eq 2 ]] &&
		PKGS+=(intel-media-driver intel-media-sdk)

	# Early load KMS driver
	if [[ ! -a "/tmp/intel_early_kms.empty" ]]; then
		echo -e "\nMODULES+=(i915)" >>/etc/mkinitcpio.conf
		touch "/tmp/intel_early_kms.empty"
	fi
}

# grep: -P/--perl-regexp benched faster than -E/--extended-regexp
# shellcheck disable=SC2249
case $(lspci | grep -P "VGA|3D|Display" | grep -Po "AMD|NVIDIA|Intel") in
*"AMD"*)
	[[ ${gpu_selected} -eq 1 ]] &&
		AMDGPUSetup
	;;&
*"NVIDIA"*)
	[[ ${gpu_selected} -eq 2 ]] &&
		NvidiaGPUSetup
	;;&
*"Intel"*)
	[[ ${gpu_selected} -eq 3 ]] &&
		IntelGPUSetup
	;;
esac

_pkgs_add
_pkgs_aur_add
_flatpaks_add

cleanup() {
	mkdir "${mkdir_flags}" "${BACKUPS}/etc/modprobe.d"
	chown -R "${WHICH_USER}:${WHICH_USER}" "${BACKUPS}/etc/modprobe.d"
}
trap cleanup EXIT
