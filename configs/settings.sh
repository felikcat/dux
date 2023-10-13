#!/bin/bash
# shellcheck disable=SC2034,SC2249
set -a

# Disk encryption.
use_luks2="1"

# 1: GRUB2 (recommended)
# 2: rEFInd
bootloader_chosen="1"

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

#- Download server region selection
#! Countries not listed here are discouraged.
# North America:    "US,CA"
# South America:    "BR,MX,US"
# Europe #1:        "DE,NL"
# Europe #2:        "SE,FI,NO"
# South Africa:     "ZA,KE,PT,FR"
# West Asia:        "IL,IT,FR"
# NE Asia:          "JP,SK,TW"
# SE Asia:          "SG,HK"
# Oceania:          "AU,NZ,SG"
#
reflector_countrylist="US,CA"

# 0:  No desktop environment; Do It Yourself.
# 1:  GNOME -> https://www.gnome.org/
# 2:  IceWM -> https://ice-wm.org/
# 99: Server usage; no desktop environment, and no accommodations for desktop usage.
desktop_environment="1"

# === Desktop Environment: GNOME ===
# GNOME Display Manager: auto-start and login into GNOME; recommended if using LUKS.
gdm_auto_login="1"

# It's not recommended to run the stock GNOME.
allow_gnome_rice="1"

if [[ ${allow_gnome_rice} -eq 1 ]]; then
    gnome_animations="false"            # true, false
    gnome_mouse_accel_profile="flat"    # flat, adaptive, default
    gnome_remember_app_usage="false"    # true, false
    gnome_remember_recent_files="false" # true, false
    gnome_center_new_windows="true"     # true, false

    # Support for tray icons; some programs still rely on it.
    gnome_extension_appindicator="1"

    # Disable automatically turning off the screen/display.
    gnome_no_idle="1"

    # Disables drop-down shadows that draw under currently active windows.
    gnome_no_window_shadows="1"
fi


# === Graphics Card options ===
# 1: Skip installing GPU software.
disable_gpu="0"

# Enforce "Prefer Maximum Performance" (some GPUs lag hard without this).
nvidia_force_max_performance="0"

# https://docs.nvidia.com/cuda/cuda-driver-api/group__CUDA__MEMOP.html#group__CUDA__MEMOP
nvidia_stream_memory_operations="0"

# Enables hardware video acceleration; use 2 if possible.
# 1: GMA 4500 (2008) up to Coffee Lake's (2017) HD Graphics.
# 2: HD Graphics series starting from Broadwell (2014) and newer.
intel_video_accel="2"
