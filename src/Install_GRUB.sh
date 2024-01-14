#!/bin/bash
set +H
set -e

SRC_DIR=$(dirname "$(realpath -s "$(dirname "$0")")")
source "${SRC_DIR}/GLOBAL_IMPORTS.sh"
source "${SRC_DIR}/Configs/settings.sh"

ROOT_DISK=$(blkid -s UUID -s TYPE | sed -n '/crypto_LUKS/p' | cut -f2 -d' ' | cut -d '=' -f2 | sed 's/\"//g')
REQUIRED_PARAMS="splash rd.luks.name=${ROOT_DISK}=root rd.luks.options=discard root=/dev/mapper/root rootflags=subvol=@root rw"
APPARMOR="lsm=landlock,lockdown,yama,integrity,apparmor,bpf"

# loglevel=3: print only 3 (KERN_ERR) conditions during boot process.
# acpi_osi=Linux: tell the motherboard's BIOS to load their ACPI tables for Linux.
COMMON_PARAMS="loglevel=3 quiet add_efi_memmap acpi_osi=Linux skew_tick=1 mce=ignore_ce nowatchdog ${MICROCODE:-}"

# --removable: would support more devices, but ruins dual-booting.
if [[ $(</sys/firmware/efi/fw_platform_size) -eq 64 ]]; then
    grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB
elif [[ $(</sys/firmware/efi/fw_platform_size) -eq 32 ]]; then
    grub-install --target=i386-efi --efi-directory=/boot --bootloader-id=GRUB
fi

ConfigGRUB() {
    sed -i -e "s/.GRUB_CMDLINE_LINUX/GRUB_CMDLINE_LINUX/" \
        -e "s/.GRUB_CMDLINE_LINUX_DEFAULT/GRUB_CMDLINE_LINUX_DEFAULT/" \
        -e "s/.GRUB_DISABLE_OS_PROBER/GRUB_DISABLE_OS_PROBER/" \
        "${BOOT_CONF}" # can't allow these to be commented out

    sed -i -e "s|GRUB_CMDLINE_LINUX=.*|GRUB_CMDLINE_LINUX=\"${REQUIRED_PARAMS} ${MITIGATIONS_OFF:-}\"|" \
        -e "s|GRUB_CMDLINE_LINUX_DEFAULT=.*|GRUB_CMDLINE_LINUX_DEFAULT=\"${COMMON_PARAMS} ${APPARMOR}\"|" \
        -e "s|GRUB_DISABLE_OS_PROBER=.*|GRUB_DISABLE_OS_PROBER=false|" \
        "${BOOT_CONF}"
}
ConfigGRUB
