#!/bin/bash
set +H
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "${SCRIPT_DIR}" && GIT_DIR=$(git rev-parse --show-toplevel)
source "${GIT_DIR}/scripts/GLOBAL_IMPORTS.sh"
source "${GIT_DIR}/configs/settings.sh"

ConfigSDDM() {
    systemctl disable entrance.service lightdm.service lxdm.service xdm.service tdm.service gdm.service >&/dev/null || :
	SERVICES+=(sddm.service)

    local CONF="/etc/sddm.conf.d/99-autologin.conf"
    kwriteconfig5 --file "${CONF}" --group "Autologin" --key "User" "${YOUR_USER}"
    kwriteconfig5 --file "${CONF}" --group "Autologin" --key "Session" "plasma"
}

ConfigKDE(){
    rm "/home/${YOUR_USER}/.config/environment.d/gnome.conf"
    \cp "${cp_flags}" "${GIT_DIR}"/files/home/.config/environment.d/kde.conf "/home/${YOUR_USER}/.config/environment.d/"
}

# spectacle: screenshot utility.
PKGS+=(plasma spectacle)
_pkgs_add
ConfigSDDM