#!/bin/bash
set +H
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "${SCRIPT_DIR}" && GIT_DIR=$(git rev-parse --show-toplevel)
source "${GIT_DIR}/scripts/GLOBAL_IMPORTS.sh"
source "${GIT_DIR}/configs/settings.sh"

ConfigGDM() {
	GDM_CONF="/etc/gdm/custom.conf"

	_move2bkup "${GDM_CONF}" &&
		\cp "${cp_flags}" "${GIT_DIR}"/files/etc/gdm/custom.conf "/etc/gdm/"

	sed -i "s/AutomaticLogin=~GNOME.sh~/AutomaticLogin=${WHICH_USER}/" "${GDM_CONF}"

	[[ ${gdm_auto_login} -eq 1 ]] &&
		sed -i "s/AutomaticLoginEnable=.*/AutomaticLoginEnable=True/" "${GDM_CONF}"

	[[ ${gdm_disable_wayland} -eq 1 ]] &&
		sed -i '/^#WaylandEnable/s/^#//' "${GDM_CONF}"

	systemctl disable entrance.service lightdm.service lxdm.service xdm.service tdm.service sddm.service >&/dev/null || :
	SERVICES+="gdm.service "
}

# At one point it was required to install these before the rest of GNOME.
PKGS="gdm libnm libnma "
_pkgs_add
PKGS=""

# gst-plugins-good -> Required for:
# - Animated setting previews, such as Mouse & Touchpad -> Scroll Direction.
# Language support list for the spell checking: https://archlinux.org/packages/?q=hunspell-
# xdg-user-dirs: Some XDG compliant programs rely on this.
PKGS+="ttf-liberation ttf-carlito ttf-caladea ttf-hack inter-font \
gnome-themes-extra gnome-shell gnome-session gnome-control-center networkmanager gst-plugins-base gst-plugins-good \
gsettings-desktop-schemas flatpak xdg-desktop-portal xdg-desktop-portal-gtk ibus xdg-desktop-portal-gnome xdg-user-dirs \
gnome-clocks gnome-weather gnome-logs \
konsole kconfig dconf-editor seahorse \
qt5-wayland qt6-wayland \
nuspell hunspell-en_us"

# Adds full support for AppImages.
PKGS_AUR+="appimagelauncher "


ConfigGDM
_pkgs_add
_pkgs_aur_add || :
ConfigFlatpak

ConfigNetworkmanager() {
	local DIR="etc/NetworkManager/conf.d"
	# Use openresolv instead of systemd-resolvconf.
	\cp "${cp_flags}" "${GIT_DIR}"/files/"${DIR}"/rc-manager.conf "/${DIR}/"
	# Use dnsmasq instead of systemd-resolved.
	\cp "${cp_flags}" "${GIT_DIR}"/files/"${DIR}"/dns.conf "/${DIR}/"
	# Tell NetworkManager to use iwd by default for increased WiFi reliability and speed.
    \cp "${cp_flags}" "${GIT_DIR}/files/etc/NetworkManager/conf.d/wifi_backend.conf" "/${DIR}/"

    SERVICES+="NetworkManager.service "
    # These conflict with NetworkManager.
    systemctl disable connman.service systemd-networkd.service iwd.service >&/dev/null || :
}
ConfigNetworkmanager

# shellcheck disable=SC2086
_systemctl enable ${SERVICES}
