#!/bin/bash
set +H
set -e

SRC_DIR=$(dirname "$(realpath -s "$(dirname "$0")")")
source "${SRC_DIR}/GLOBAL_IMPORTS.sh"
source "${SRC_DIR}/Configs/settings.sh"

ConfigSDDM() {
    systemctl disable entrance.service lightdm.service lxdm.service xdm.service tdm.service gdm.service >&/dev/null || :
	SERVICES+=(sddm.service)
    
    local CONF="/etc/sddm.conf.d/kde_settings.conf"
    kwriteconfig5 --file "${CONF}" --group "Autologin" --key "User" "${YOUR_USER}"
    kwriteconfig5 --file "${CONF}" --group "Autologin" --key "Session" "plasmawayland"
    kwriteconfig5 --file "${CONF}" --group "Theme" --key "Current" "breeze"
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

ConfigFirewalls_Part1(){
    # For OpenSnitch support.
    echo "
debugfs    /sys/kernel/debug      debugfs  defaults  0 0" >> /etc/fstab

    # Block incoming traffic by default; force hosting to be intentional.
    ufw default deny
    ufw enable
    SERVICES+=(opensnitchd.service ufw.service)
}

# Makes our font and cursor settings work inside Flatpak.
ConfigFlatpak_Part1() {
    # Flatpak requires this for "--filesystem=xdg-config/fontconfig:ro"
    _move2bkup "/etc/fonts/local.conf" &&
    	\cp "${cp_flags}" "${SRC_DIR}/Files/etc/fonts/local.conf" "/etc/fonts/"

    FLATPAK_PARAMS="--filesystem=xdg-config/fontconfig:ro \
    --filesystem=/home/${YOUR_USER}/.icons/:ro --filesystem=/home/${YOUR_USER}/.local/share/icons/:ro \
    --filesystem=/usr/share/icons/:ro --filesystem=xdg-config/gtk-3.0:ro"

    if [[ ${DEBUG} -eq 1 ]]; then
        # shellcheck disable=SC2086
        flatpak -vv override --system ${FLATPAK_PARAMS}
    else
        # shellcheck disable=SC2086
        flatpak override --system ${FLATPAK_PARAMS}
    fi
}

# sddm: KDE's default login manager.
# libdecor, qt5/6-wayland: Run more programs in Wayland instead of Xorg.
# spectacle: Screenshot Utility.
# opensnitch: Interactive Firewall for programs you run.
# ufw: Firewall for hosting purposes.
# konsole: Terminal Emulator.
# xdg-desktop-portal-gnome: Required to launch some Flatpaks, such as Telegram Desktop.
# libgnome-keyring, libnotify: Firefox (non Flatpak version) requires this for keyring support.
# libappindicator-gtk3: Tray icon support for a few programs.
#
# dolphin: File browser.
# -> ark: File archive support, such as Zip and 7z.
#    -> unrar: Unarchiving .rar file support.
# -> packagekit-qt5: Required for "Configure > Configure Dolphin > Context Menu > Download New Services".
# -> meld: "Compare files" support.
# noto-fonts-*: The best supported fonts for making sure characters don't display as blank boxes.
# gnome-logs: To better your ability to tell what's going on with your Linux PC.
PKGS+=(sddm
libdecor qt5-wayland qt6-wayland
plasma plasma-wayland-session spectacle opensnitch ufw konsole
xdg-desktop-portal-gnome libgnome-keyring libnotify libappindicator-gtk3
dolphin kconfig5 kde-cli-tools kdegraphics-thumbnailers kimageformats5 qt5-imageformats ffmpegthumbs taglib openexr libjxl android-udev packagekit-qt5 packagekit-qt6 meld
ark unrar
noto-fonts-emoji noto-fonts-cjk
gnome-logs
)
PKGS_AUR+=(opensnitch-ebpf-module)
_pkgs_add
_pkgs_aur_add

ConfigSDDM
ConfigNetworkmanager
ConfigFirewalls_Part1
ConfigFlatpak_Part1

chmod +x "${SRC_DIR}/KDE_user.sh"
sudo -H -u "${YOUR_USER}" bash -c "${SRC_DIR}/KDE_user.sh"

systemctl enable "${SERVICES[@]}"
