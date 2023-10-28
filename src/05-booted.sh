#!/bin/bash
set +H
set -e

SRC_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SRC_DIR}/GLOBAL_IMPORTS.sh"
source "${SRC_DIR}/Configs/settings.sh"

if [[ $(systemd-detect-virt) = "vmware" ]]; then
    \cp ${cp_flags} ${SRC_DIR}/Files/home/.config/systemd/user/vmware-user.service /home/${YOUR_USER}/.config/systemd/user/"
    systemctl --user enable vmware-user.service"
fi

systemctl --user enable dbus-broker.service

# Makes our font and cursor settings work inside Flatpak.
ConfigFlatpak() {
    # Flatpak requires this for "--filesystem=xdg-config/fontconfig:ro"
    _move2bkup "/etc/fonts/local.conf" &&
    	\cp "${cp_flags}" "${SRC_DIR}/Files/etc/fonts/local.conf" "/etc/fonts/"

    _move2bkup "/home/${YOUR_USER}/.config/fontconfig/conf.d/99-custom.conf" &&
        \cp "${cp_flags}" /etc/fonts/local.conf "/home/${YOUR_USER}/.config/fontconfig/conf.d/" &&
            chown -R "${YOUR_USER}:${YOUR_USER}" "/home/${YOUR_USER}/.config/fontconfig/conf.d/"

    FLATPAK_PARAMS="--filesystem=xdg-config/fontconfig:ro --filesystem=/home/${YOUR_USER}/.icons/:ro --filesystem=/home/${YOUR_USER}/.local/share/icons/:ro --filesystem=/usr/share/icons/:ro"
    if [[ ${DEBUG} -eq 1 ]]; then
        # shellcheck disable=SC2086
        sudo flatpak -vv override ${FLATPAK_PARAMS}
        # Cannot run at all under sudo!
        flatpak --user -vv override ${FLATPAK_PARAMS}
    else
        # shellcheck disable=SC2086
        sudo flatpak override ${FLATPAK_PARAMS}
        flatpak --user override ${FLATPAK_PARAMS}
    fi
}

# Scripts in "_do_last" have to forcefully logout to apply changes.
DoLast() {
	sudo chown -R "${YOUR_USER}:${YOUR_USER}" /home/"${YOUR_USER}"/{dux,dux_backups}
}
trap DoLast EXIT
