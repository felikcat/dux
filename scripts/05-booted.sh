#!/bin/bash
set +H
set -e

export DENY_SUPERUSER=1

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "${SCRIPT_DIR}" && GIT_DIR=$(git rev-parse --show-toplevel)
source "${GIT_DIR}/scripts/GLOBAL_IMPORTS.sh"
source "${GIT_DIR}/configs/settings.sh"

if [[ $(systemd-detect-virt) = "vmware" ]]; then
    \cp ${cp_flags} ${GIT_DIR}/files/home/.config/systemd/user/vmware-user.service /home/${YOUR_USER}/.config/systemd/user/"
    systemctl --user enable vmware-user.service"
fi

systemctl --user enable dbus-broker.service

# Makes our font and cursor settings work inside Flatpak.
ConfigFlatpak() {
    # Flatpak requires this for "--filesystem=xdg-config/fontconfig:ro"
    _move2bkup "/etc/fonts/local.conf" &&
    	\cp "${cp_flags}" "${GIT_DIR}"/files/etc/fonts/local.conf "/etc/fonts/"

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

GnomeSpecific() {
	FLATPAKS+="org.kde.KStyle.Kvantum//5.15-22.08 org.gtk.Gtk3theme.adw-gtk3-dark"
	_flatpaks_add

	sudo flatpak override --env=QT_STYLE_OVERRIDE=kvantum --filesystem=xdg-config/Kvantum:ro
}
[[ ${desktop_environment} -eq 1 ]] && GnomeSpecific

# Scripts in "_do_last" have to forcefully logout to apply changes.
DoLast() {
    if [[ ${desktop_environment} -eq 1 ]]; then
        RiceGNOME() {
            (sudo bash "${GIT_DIR}/scripts/DE/GNOME_Rice_1.sh") |& tee "${GIT_DIR}/logs/GNOME_Rice_1.log" || return
        }
        [[ ${allow_gnome_rice} -eq 1 ]] && RiceGNOME
    fi

	sudo chown -R "${YOUR_USER}:${YOUR_USER}" /home/"${YOUR_USER}"/{dux,dux_backups}
}
trap DoLast EXIT
