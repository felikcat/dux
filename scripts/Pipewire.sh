#!/bin/bash
set +H
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "${SCRIPT_DIR}" && GIT_DIR=$(git rev-parse --show-toplevel)
source "${GIT_DIR}/scripts/GLOBAL_IMPORTS.sh"

groupadd --force -g 509 pipewire
gpasswd -a "${YOUR_USER}" pipewire

PKGS+=(rtkit alsa-firmware sof-firmware alsa-ucm-conf
pipewire wireplumber pipewire-alsa pipewire-pulse pipewire-jack pipewire-zeroconf pipewire-v4l2
lib32-pipewire lib32-pipewire-jack gst-plugin-pipewire
libpulse lib32-libpulse alsa-plugins lib32-alsa-plugins alsa-lib lib32-alsa-lib)
_pkgs_add

# Maintain Pipewire performance without resorting to adding ${YOUR_USER} to 'realtime' group.
mkdir "${mkdir_flags}" /etc/security/limits.d
\cp "${cp_flags}" "${GIT_DIR}"/files/etc/security/limits.d/95-pipewire.conf "/etc/security/limits.d/"

# Lowers audio latency (delay) and keeps it consistent.
\cp "${cp_flags}" -R "${GIT_DIR}"/files/etc/pipewire/ "/etc/"

# Some games using an old version of the FMOD audio engine invoke pulseaudio --check and crash if that command fails.
ln -sf /bin/true /bin/pulseaudio
