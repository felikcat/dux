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
    # For OpenSnitch support.
    echo "
debugfs    /sys/kernel/debug      debugfs  defaults  0 0" >> /etc/fstab

    # Block incoming traffic by default; force hosting to be intentional.
    ufw default deny
    ufw enable
    SERVICES+=(opensnitchd.service ufw.service)
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

ConfigDolphin() {
    local CONF="/home/${YOUR_USER}/.config/dolphinrc"
    kwriteconfig5 --file "${CONF}" --group "General" --key "ShowFullPath" "true"
    kwriteconfig5 --file "${CONF}" --group "General" --key "ShowSpaceInfo" "false"
    # Allow loading of larger images that are remotely located, such as on an SMB server.
    kwriteconfig5 --file "/home/${YOUR_USER}/.config/kdeglobals" --group "PreviewSettings" --key "MaximumRemoteSize" "10485760"
}

# spectacle: Screenshot Utility.
# opensnitch: Interactive Firewall for programs you run.
# ufw: Firewall for hosting purposes.
# konsole: Terminal Emulator.
# xdg-desktop-portal-gnome: Required to launch some Flatpaks, such as Telegram Desktop.
# libgnome-keyring, libnotify: Firefox (non Flatpak version) requires this for keyring support.
#
# dolphin: File browser.
# -> ark: File archive support, such as Zip and 7z.
# -> packagekit-qt5: Required for "Configure > Configure Dolphin > Context Menu > Download New Services".
# -> meld: "Compare files" support.
PKGS+=(plasma plasma-wayland-session spectacle opensnitch ufw konsole
xdg-desktop-portal-gnome libgnome-keyring libnotify
dolphin ark kconfig5 kde-cli-tools kdegraphics-thumbnailers kimageformats5 qt5-imageformats ffmpegthumbs taglib openexr libjxl android-udev packagekit-qt5 packagekit-qt6 meld
)
PKGS_AUR+=(opensnitch-ebpf-module)
_pkgs_add
_pkgs_aur_add

ConfigSDDM
ConfigKDE
ConfigNetworkmanager
ConfigFirewalls
ConfigFlatpak
ConfigDolphin
SetupUserServices

systemctl enable "${SERVICES[@]}"
