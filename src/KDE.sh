#!/bin/bash
set +H
set -e

SRC_DIR=$(dirname "$(realpath -s "${BASH_SOURCE[0]}")")
source "${SRC_DIR}/GLOBAL_IMPORTS.sh"
source "${SRC_DIR}/Configs/settings.sh"

ConfigSDDM() {
    systemctl disable entrance.service lightdm.service lxdm.service xdm.service tdm.service gdm.service >&/dev/null || :
	SERVICES+=(sddm.service)

    local CONF="/etc/sddm.conf.d/99-autologin.conf"
    kwriteconfig5 --file "${CONF}" --group "Autologin" --key "User" "${YOUR_USER}"
    kwriteconfig5 --file "${CONF}" --group "Autologin" --key "Session" "plasma"

    local CONF="/etc/sddm.conf.d/kde_settings.conf"
    kwriteconfig5 --file "${CONF}" --group "Theme" --key "Current" "breeze"
}

ConfigKDE(){
    rm "/home/${YOUR_USER}/.config/environment.d/gnome.conf"
    \cp "${cp_flags}" "${SRC_DIR}/Files/home/.config/environment.d/kde.conf" "/home/${YOUR_USER}/.config/environment.d/"
}

ConfigNetworkmanager() {
	local DIR="etc/NetworkManager/conf.d"
	# Use openresolv instead of systemd-resolvconf.
	\cp "${cp_flags}" "${SRC_DIR}/Files/${DIR}/rc-manager.conf" "/${DIR}/"
	# Use dnsmasq instead of systemd-resolved.
	\cp "${cp_flags}" "${SRC_DIR}/Files/${DIR}/dns.conf" "/${DIR}/"
	# Tell NetworkManager to use iwd by default for increased WiFi reliability and speed.
    \cp "${cp_flags}" "${SRC_DIR}/Files/etc/NetworkManager/conf.d/wifi_backend.conf" "/${DIR}/"

    SERVICES+=(NetworkManager.service)
    # These conflict with NetworkManager.
    systemctl disable connman.service systemd-networkd.service iwd.service >&/dev/null || :
}

ConfigFirewalls(){
    echo "
debugfs    /sys/kernel/debug      debugfs  defaults  0 0" >> /etc/fstab
    # Block incoming traffic by default; force hosting to be intentional.
    ufw default deny
    SERVICES+=(ufw.service)
}

# spectacle: screenshot utility.
# opensnitch: interactive firewall for programs you run.
# ufw: firewall for hosting purposes.
PKGS+=(plasma spectacle opensnitch ufw)
PKGS_AUR+=(opensnitch-ebpf-module)
_pkgs_add
_pkgs_aur_add

ConfigSDDM
ConfigKDE
ConfigNetworkmanager
ConfigFirewalls

systemctl enable "${SERVICES[@]}"
