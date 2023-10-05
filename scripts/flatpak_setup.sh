#!/bin/bash
set +H
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "${SCRIPT_DIR}" && GIT_DIR=$(git rev-parse --show-toplevel)
source "${GIT_DIR}/scripts/GLOBAL_IMPORTS.sh"
source "${GIT_DIR}/configs/settings.sh"

# Makes our font and cursor settings work inside Flatpak.
ConfigFlatpak() {
    # Flatpak requires this for "--filesystem=xdg-config/fontconfig:ro"
    _move2bkup "/etc/fonts/local.conf" &&
    	\cp "${cp_flags}" "${GIT_DIR}"/files/etc/fonts/local.conf "/etc/fonts/"

    _move2bkup "/home/${WHICH_USER}/.config/fontconfig/conf.d/99-custom.conf" &&
            \cp "${cp_flags}" /etc/fonts/local.conf "/home/${WHICH_USER}/.config/fontconfig/conf.d/" &&
            chown -R "${WHICH_USER}:${WHICH_USER}" "/home/${WHICH_USER}/.config/fontconfig/conf.d/"

    FLATPAK_PARAMS="--filesystem=xdg-config/fontconfig:ro --filesystem=/home/${WHICH_USER}/.icons/:ro --filesystem=/home/${WHICH_USER}/.local/share/icons/:ro --filesystem=/usr/share/icons/:ro"
    if [[ ${DEBUG} -eq 1 ]]; then
        # shellcheck disable=SC2086
        flatpak -vv override ${FLATPAK_PARAMS}
        sudo -H -u "${WHICH_USER}" DENY_SUPERUSER=1 ${SYSTEMD_USER_ENV} flatpak --user -vv override ${FLATPAK_PARAMS}
    else
        # shellcheck disable=SC2086
        flatpak override ${FLATPAK_PARAMS}
        sudo -H -u "${WHICH_USER}" DENY_SUPERUSER=1 ${SYSTEMD_USER_ENV} flatpak --user override ${FLATPAK_PARAMS}
    fi
}