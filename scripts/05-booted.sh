#!/bin/bash
set +H
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "${SCRIPT_DIR}" && GIT_DIR=$(git rev-parse --show-toplevel)
source "${GIT_DIR}/scripts/GLOBAL_IMPORTS.sh"
source "${GIT_DIR}/configs/settings.sh"


if [[ $(systemd-detect-virt) = "vmware" ]]; then
    sudo -H -u "${WHICH_USER}" bash -c "${SYSTEMD_USER_ENV} DENY_SUPERUSER=1 \cp ${cp_flags} ${GIT_DIR}/files/home/.config/systemd/user/vmware-user.service /home/${WHICH_USER}/.config/systemd/user/"
    sudo -H -u "${WHICH_USER}" bash -c "${SYSTEMD_USER_ENV} systemctl --user enable vmware-user.service"
fi

sudo -H -u "${WHICH_USER}" bash -c "${SYSTEMD_USER_ENV} systemctl --user enable dbus-broker.service"

# Scripts in "_do_last" have to forcefully logout to apply changes.
_do_last() {
    if [[ ${desktop_environment} -eq 1 ]]; then
        _gnome_rice() {
            (bash "${GIT_DIR}/scripts/GNOME_Rice_1.sh") |& tee "${GIT_DIR}/logs/GNOME_Rice_1.log" || return
        }
        [[ ${allow_gnome_rice} -eq 1 ]] && _gnome_rice
    fi

	chown -R "${WHICH_USER}:${WHICH_USER}" /home/"${WHICH_USER}"/{dux,dux_backups}
}
trap _do_last EXIT
