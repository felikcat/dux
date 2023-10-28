#!/bin/bash
set +H
set -e

SRC_DIR=$(dirname "$(realpath -s "${BASH_SOURCE[0]}")")
source "${SRC_DIR}/GLOBAL_IMPORTS.sh"
source "${SRC_DIR}/Configs/settings.sh"

ROOT_DISK=$(blkid -s UUID -s TYPE | sed -n '/crypto_LUKS/p' | cut -f2 -d' ' | cut -d '=' -f2 | sed 's/\"//g')
REQUIRED_PARAMS="rd.luks.name=${ROOT_DISK}=root rd.luks.options=discard root=/dev/mapper/root rootflags=subvol=@root rw"

# loglevel=3: print only 3 (KERN_ERR) conditions during boot process.
# acpi_osi=Linux: tell the motherboard's BIOS to load their ACPI tables for Linux.
# usbcore.autosuspend=-1: never auto-suspend USB devices, to prevent stuttering on wireless mice.
COMMON_PARAMS="loglevel=3 quiet add_efi_memmap acpi_osi=Linux skew_tick=1 mce=ignore_ce nowatchdog tsc=reliable no_timer_check usbcore.autosuspend=-1 ${MICROCODE:-}"

# --removable: Support for MSI motherboards.
if [[ $(</sys/firmware/efi/fw_platform_size) -eq 64 ]]; then
    grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB --removable
elif [[ $(</sys/firmware/efi/fw_platform_size) -eq 32 ]]; then
    grub-install --target=i386-efi --efi-directory=/boot --bootloader-id=GRUB --removable
fi

ConfigGRUB() {
    sed -i -e "s/.GRUB_CMDLINE_LINUX/GRUB_CMDLINE_LINUX/" \
        -e "s/.GRUB_CMDLINE_LINUX_DEFAULT/GRUB_CMDLINE_LINUX_DEFAULT/" \
        -e "s/.GRUB_DISABLE_OS_PROBER/GRUB_DISABLE_OS_PROBER/" \
        "${BOOT_CONF}" # can't allow these to be commented out

    sed -i -e "s|GRUB_CMDLINE_LINUX=.*|GRUB_CMDLINE_LINUX=\"${MITIGATIONS_OFF:-} ${REQUIRED_PARAMS}\"|" \
        -e "s|GRUB_CMDLINE_LINUX_DEFAULT=.*|GRUB_CMDLINE_LINUX_DEFAULT=\"${COMMON_PARAMS}\"|" \
        -e "s|GRUB_DISABLE_OS_PROBER=.*|GRUB_DISABLE_OS_PROBER=false|" \
        "${BOOT_CONF}"
}
ConfigGRUB