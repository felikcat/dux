#!/bin/bash
set +H
set -e

SRC_DIR=$(dirname "$(realpath -s "${BASH_SOURCE[0]}")")
source "${SRC_DIR}/GLOBAL_IMPORTS.sh"
source "${SRC_DIR}/Configs/settings.sh"

REQUIRED_PARAMS="rd.luks.name=${ROOT_DISK}=root rd.luks.options=discard root=/dev/mapper/root rootflags=subvol=@root rw"

# loglevel=3: print only 3 (KERN_ERR) conditions during boot process.
# acpi_osi=Linux: tell the motherboard's BIOS to load their ACPI tables for Linux.
# usbcore.autosuspend=-1: never auto-suspend USB devices, to prevent stuttering on wireless mice.
COMMON_PARAMS="loglevel=3 quiet add_efi_memmap acpi_osi=Linux skew_tick=1 mce=ignore_ce nowatchdog tsc=reliable no_timer_check usbcore.autosuspend=-1 ${MICROCODE:-}"

# --removable: Support for MSI motherboards.
grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB --removable
