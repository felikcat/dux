#!/bin/bash
set +H
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "${SCRIPT_DIR}" && GIT_DIR=$(git rev-parse --show-toplevel)
source "${GIT_DIR}/scripts/GLOBAL_IMPORTS.sh"
source "${GIT_DIR}/configs/settings.sh"

PKGS_AUR=(arc-kde kvantum-theme-arc)
_pkgs_aur_add

echo "dbus-update-activation-environment --systemd --all
xrdb -merge ~/.Xresources
lxqt-policykit-agent &
exec icewm-session" > ${YOUR_USER}/.xinitrc

mkdir -p ${YOUR_USER}/.icewm/themes
\cp ${cp_flags} "${GIT_DIR}"/files/THIRD-PARTY/Arc-Ice-1.3.tar.xz ${YOUR_USER}/.icewm/themes
tar xpvf ${YOUR_USER}/.icewm/themes/Arc-Ice-1.3.tar.xz
rm -f ${YOUR_USER}/.icewm/themes/Arc-Ice-1.3.tar.xz
