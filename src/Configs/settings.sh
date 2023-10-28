#!/bin/bash
# shellcheck disable=SC2034,SC2249
set -a

# Do not use any of the following: symbols, spaces, upper-case letters.
YOUR_USER="admin"

# Do not use any of the following: symbols, spaces.
system_hostname="arch"

# Controls keyboard layout.
# by ca cf cz de dk es et fa fi fr gr hu il it lt lv mk nl no pl ro ru sg ua uk us
system_keymap="us"

# NOTE: Wi-Fi and Bluetooth are inseparable here.
hardware_wifi_and_bluetooth="1"

# Supported printer list: https://www.openprinting.org/printers
hardware_printers_and_scanners="1"

# 0: Incurs a massive performance penalty on CPUs older than AMD Zen 2 or Intel 10th gen.
# 1: Disables all CPU security mitigations.
no_mitigations="0"


# === Graphics Card options ===
# 1: Skip installing GPU software.
disable_gpu="0"

# https://docs.nvidia.com/cuda/cuda-driver-api/group__CUDA__MEMOP.html#group__CUDA__MEMOP
nvidia_stream_memory_operations="0"

# Enables hardware video acceleration; use 2 if possible.
# 1: GMA 4500 (2008) up to Coffee Lake's (2017) HD Graphics.
# 2: HD Graphics series starting from Broadwell (2014) and newer.
intel_video_accel="2"
