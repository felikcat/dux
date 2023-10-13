#!/bin/bash
set +H
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "${SCRIPT_DIR}" && GIT_DIR=$(git rev-parse --show-toplevel)
source "${GIT_DIR}/scripts/GLOBAL_IMPORTS.sh"
source "${GIT_DIR}/configs/settings.sh"

# lxqt-policykit: Polkit support; asks for privilege escalation with a GUI prompt.
# lxrandr-gtk3: Display resolution / refresh rate configurator.
PKGS=(icewm xorg-xinit lxqt-policykit lxrandr-gtk3 arc-gtk-theme)

_pkgs_add

bash "/home/${INITIAL_USER}/dux/scripts/DE/IceWM_Rice.sh" |& tee "${GIT_DIR}/logs/IceWM_Rice.log"
