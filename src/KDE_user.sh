#!/bin/bash
set +H
set -e

SRC_DIR=$(dirname "$(realpath -s "${BASH_SOURCE[0]}")")
source "${SRC_DIR}/GLOBAL_IMPORTS.sh"
source "${SRC_DIR}/Configs/settings.sh"

ConfigDolphin() {
    local CONF="/home/${YOUR_USER}/.config/dolphinrc"
    kwriteconfig5 --file "${CONF}" --group "General" --key "ShowFullPath" "true"
    kwriteconfig5 --file "${CONF}" --group "General" --key "ShowSpaceInfo" "false"

    # Allow loading of larger images that are remotely located, such as on an SMB server.
    kwriteconfig5 --file "/home/${YOUR_USER}/.config/kdeglobals" --group "PreviewSettings" --key "MaximumRemoteSize" "10485760"
}

SetupUserServices() {
    if [[ $(systemd-detect-virt) = "vmware" ]]; then
        \cp ${cp_flags} "${SRC_DIR}/Files/home/.config/systemd/user/vmware-user.service" "/home/${YOUR_USER}/.config/systemd/user/"
        systemctl --user enable vmware-user.service
    fi

    systemctl --user enable dbus-broker.service
}

ConfigFlatpak_Part2() {
    _move2bkup "/home/${YOUR_USER}/.config/fontconfig/conf.d/99-custom.conf" &&
    \cp "${cp_flags}" /etc/fonts/local.conf "/home/${YOUR_USER}/.config/fontconfig/conf.d/" &&
}

ConfigFirewalls_Part2(){
    mkdir -p /home/${YOUR_USER}/.config/{autostart,opensnitch}

    \cp "${cp_flags}" "/usr/share/applications/opensnitch_ui.desktop" "/home/${YOUR_USER}/.config/autostart"

    local CONF="/home/${YOUR_USER}/.config/opensnitch/settings.conf"
    # Preferences -> Pop-ups -> Duration: forever
    kwriteconfig5 --file "${CONF}" --group "global" --key "default_duration" "7"
}

ConfigKDE() {
   \cp "${cp_flags}" "${SRC_DIR}/Files/home/.config/environment.d/kde.conf" "/home/${YOUR_USER}/.config/environment.d/"
    
    local CONF="/home/${YOUR_USER}/.config/kwinrc"
    kwriteconfig5 --file "${CONF}" --group "TabBox" --key "LayoutName" "thumbnail_grid"

    local CONF="/home/${YOUR_USER}/.config/breezerc"
    kwriteconfig5 --file "${CONF}" --group "Common" --key "ShadowSize" "ShadowNone"
}

ConfigDolphin
SetupUserServices
ConfigFlatpak_Part2
ConfigFirewalls_Part2
ConfigKDE
