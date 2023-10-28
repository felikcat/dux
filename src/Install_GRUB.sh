#!/bin/bash
set +H
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "${SCRIPT_DIR}" && SRC_DIR=$(git rev-parse --show-toplevel)
source "${SRC_DIR}/GLOBAL_IMPORTS.sh"
source "${SRC_DIR}/Configs/settings.sh"

