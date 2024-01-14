#!/bin/bash
set +H
set -e

SRC_DIR=$(dirname "$(realpath -s "$(dirname "$0")")")
source "${SRC_DIR}/GLOBAL_IMPORTS.sh"
source "${SRC_DIR}/Configs/settings.sh"

groupadd --force -g 509 pipewire
gpasswd -a "${YOUR_USER}" pipewire

PKGS+=(alsa-firmware sof-firmware alsa-ucm-conf
pipewire wireplumber pipewire-alsa pipewire-pulse pipewire-jack pipewire-zeroconf pipewire-v4l2
lib32-pipewire lib32-pipewire-jack gst-plugin-pipewire
libpulse lib32-libpulse alsa-plugins lib32-alsa-plugins alsa-lib lib32-alsa-lib)
_pkgs_add

# Some games using an old version of the FMOD audio engine crash if 'pulseaudio --check' fails.
ln -sf /bin/true /bin/pulseaudio
