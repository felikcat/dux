#!/bin/bash
set +H
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "${SCRIPT_DIR}" && GIT_DIR=$(git rev-parse --show-toplevel)
source "${GIT_DIR}/scripts/GLOBAL_IMPORTS.sh"
source "${GIT_DIR}/configs/settings.sh"

_setup_gdm() {
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

# Makes our font and cursor settings work inside Flatpak.
_configure_flatpak() {
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


_setup_gdm
_pkgs_add
_pkgs_aur_add || :
_configure_flatpak

_config_networkmanager() {
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
_config_networkmanager

# shellcheck disable=SC2086
_systemctl enable ${SERVICES}
