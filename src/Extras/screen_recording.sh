#!/bin/bash
set +H
set -e

SRC_DIR=$(dirname "$(realpath -s "$(dirname "$0")")")
cd ${SRC_DIR}; cd ..
source "GLOBAL_IMPORTS.sh"
source "Configs/settings.sh"

# v4l2loopback = for Virtual Camera; a good universal way to screenshare.
PKGS+=(obs-studio v4l2loopback-dkms)
if hash pipewire >&/dev/null; then
    PKGS+=(pipewire-v4l2 lib32-pipewire-v4l2)
fi
# Autostart OBS to replicate NVIDIA ShadowPlay / AMD ReLive.
AutorunOBS() {
    sudo -H -u "${YOUR_USER}" bash -c "\cp ${cp_flags} ${SRC_DIR}/Files/home/.config/systemd/user/obs-studio.service /home/${YOUR_USER}/.config/systemd/user/"
    sudo -H -u "${YOUR_USER}" bash -c "systemctl --user enable obs-studio.service"
}
