#!/bin/bash
set +H
# "|| return" is used as an error handler.
# NOTE: set -e has to be present in the scripts executed here for this to work.
set -eo pipefail

# Prevent installation issues arising from an inaccurate system time.
timedatectl set-ntp true
wait
systemctl restart systemd-timesyncd.service
wait

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "${SCRIPT_DIR}" && GIT_DIR=$(git rev-parse --show-toplevel)
source "${GIT_DIR}/scripts/GLOBAL_IMPORTS.sh"
source "${GIT_DIR}/configs/settings.sh"

if ! grep -q "'archiso'" /etc/mkinitcpio.d/linux.preset; then
	echo -e "\nERROR: Do not run this script outside of the Arch Linux ISO!\n"
	exit 1
fi
if [[ ${use_luks2} -eq 1 ]]; then
	if cryptsetup status "root" | grep -q "inactive"; then
		echo -e "\nERROR: Forgot to mount the LUKS2 partition under the name 'root'?\n"
		exit 1
	fi
fi

mkdir -p "${GIT_DIR}/logs"
# Makes scripts below executable.
chmod +x -R "${GIT_DIR}"

clear

SetPasswordPrompt() {
	read -rp "Enter a new password for the username \"${INITIAL_USER}\": " DESIREDPW
	if [[ -z ${DESIREDPW} ]]; then
		echo -e "\nNo password was entered, please try again.\n"
		SetPasswordPrompt
	fi

	read -rp $'\nPlease repeat your password: ' PWCODE
	if [[ ${DESIREDPW} == "${PWCODE}" ]]; then
		export PWCODE
	else
		echo -e "\nPasswords do not match, please try again.\n"
		SetPasswordPrompt
	fi
}
SetPasswordPrompt

_01() {
	("${GIT_DIR}/scripts/01-pre_chroot.sh") |& tee "${GIT_DIR}/logs/01-pre_chroot.log" || return
}
_01

# /mnt needs access to Dux's contents.
[[ -d "/mnt/root/dux" ]] &&
	rm -rf "/mnt/root/dux"
\cp -f -R "${GIT_DIR}" "/mnt/root"

_02() {
	(arch-chroot /mnt "${GIT_DIR}/scripts/02-post_chroot_root.sh") |& tee "${GIT_DIR}/logs/02-post_chroot_root.log" || return
}
_02

_03() {
	(arch-chroot /mnt sudo -u "${INITIAL_USER}" DENY_SUPERUSER=1 ${SYSTEMD_USER_ENV} bash "/home/${INITIAL_USER}/dux/scripts/03-post_chroot_user.sh") |& tee "${GIT_DIR}/logs/03-post_chroot_user.log" || return
}
_03

_gpu() {
    (arch-chroot /mnt "${GIT_DIR}/scripts/GPU.sh") |& tee "${GIT_DIR}/logs/GPU.log" || return
}
[[ ${disable_gpu} -ne 1 ]] && _gpu

SetupAudio() {
	(arch-chroot /mnt "${GIT_DIR}/scripts/Pipewire.sh") |& tee "${GIT_DIR}/logs/Pipewire.log" || return
}
SetupAudio

SetupDesktopEnvironment() {
    [[ ${desktop_environment} -eq 1 ]] &&
		(arch-chroot /mnt "${GIT_DIR}/scripts/DE/GNOME.sh") |& tee "${GIT_DIR}/logs/GNOME.log" || return
	[[ ${desktop_environment} -eq 2 ]] &&
		(arch-chroot /mnt "${GIT_DIR}/scripts/DE/IceWM.sh") |& tee "${GIT_DIR}/logs/IceWM.log" || return
}
SetupDesktopEnvironment

_04() {
	(arch-chroot /mnt "${GIT_DIR}/scripts/04-finalize.sh") |& tee "${GIT_DIR}/logs/04-finalize.log" || return
}
_04

rm -rf "/mnt/root/dux/logs"
\cp -f -R "${GIT_DIR}/logs" "/mnt/root/dux"

rm -rf "/mnt/home/${INITIAL_USER:?}/dux/logs"
\cp -f -R "${GIT_DIR}/logs" "/mnt/home/${INITIAL_USER}/dux"

SetCorrectPermissions() {
	(arch-chroot /mnt "chown" -R "${INITIAL_USER}:${INITIAL_USER}" /home/"${INITIAL_USER}"/{dux,dux_backups})
}
SetCorrectPermissions

reboot -f
