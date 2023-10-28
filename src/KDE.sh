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
        flatpak -vv override ${FLATPAK_PARAMS}
    else
        # shellcheck disable=SC2086
        flatpak override ${FLATPAK_PARAMS}
    fi
}

SetupUserServices() {
    if [[ $(systemd-detect-virt) = "vmware" ]]; then
        \cp ${cp_flags} "${SRC_DIR}/Files/home/.config/systemd/user/vmware-user.service" "/home/${YOUR_USER}/.config/systemd/user/"
        sudo -H -u "${YOUR_USER}" bash -c "systemctl --user enable vmware-user.service"
    fi

    sudo -H -u "${YOUR_USER}" bash -c "systemctl --user enable dbus-broker.service"
}

# spectacle: screenshot utility.
# opensnitch: interactive firewall for programs you run.
# ufw: firewall for hosting purposes.
PKGS+=(plasma spectacle opensnitch ufw konsole)
PKGS_AUR+=(opensnitch-ebpf-module)
_pkgs_add
_pkgs_aur_add

ConfigSDDM
ConfigKDE
ConfigNetworkmanager
ConfigFirewalls
ConfigFlatpak
SetupUserServices

systemctl enable "${SERVICES[@]}"
