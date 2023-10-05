#!/bin/bash
set +H
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "${SCRIPT_DIR}" && GIT_DIR=$(git rev-parse --show-toplevel)
source "${GIT_DIR}/scripts/GLOBAL_IMPORTS.sh"
source "${GIT_DIR}/configs/settings.sh"

# lxqt-policykit: Polkit support; asks for privilege escalation with a GUI prompt.
# lxrandr-gtk3: Display resolution / refresh rate configurator.
PKGS="icewm xorg-xinit lxqt-policykit lxrandr-gtk3 arc-gtk-theme "
PKGS_AUR="arc-kde kvantum-theme-arc "

echo "dbus-update-activation-environment --systemd --all
xrdb -merge ~/.Xresources
lxqt-policykit-agent &
exec icewm-session" > ${WHICH_USER}/.xinitrc

mkdir -p ${WHICH_USER}/.icewm/themes
\cp ${cp_flags} "${GIT_DIR}"/files/THIRD-PARTY/Arc-Ice-1.3.tar.xz ${WHICH_USER}/.icewm/themes
tar xpvf ${WHICH_USER}/.icewm/themes/Arc-Ice-1.3.tar.xz
rm -f ${WHICH_USER}/.icewm/themes/Arc-Ice-1.3.tar.xz