#!/bin/bash
set +H
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "${SCRIPT_DIR}" && GIT_DIR=$(git rev-parse --show-toplevel)
source "${GIT_DIR}/scripts/GLOBAL_IMPORTS.sh"

_move2bkup /home/"${INITIAL_USER}"/.config/mpv/mpv.conf
mkdir -p /home/"${INITIAL_USER}"/.config/mpv/
\cp "${cp_flags}" "${GIT_DIR}"/files/home/.config/mpv/mpv.conf "/home/${INITIAL_USER}/.config/mpv/"
