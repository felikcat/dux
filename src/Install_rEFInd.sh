#!/bin/bash
set +H
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "${SCRIPT_DIR}" && SRC_DIR=$(git rev-parse --show-toplevel)
source "${SRC_DIR}/GLOBAL_IMPORTS.sh"
source "${SRC_DIR}/Configs/settings.sh"

BOOT_DISK=$(blkid -s PARTLABEL -s PARTUUID | sed -n '/"BOOTEFI"/p' | cut -f1 -d':')

ROOT_DISK=$(blkid -s UUID -s TYPE | sed -n '/crypto_LUKS/p' | cut -f2 -d' ' | cut -d '=' -f2 | sed 's/\"//g')

[[ ${no_mitigations} -eq 1 ]] &&
	MITIGATIONS_OFF="mitigations=off"

REQUIRED_PARAMS="rd.luks.name=${ROOT_DISK}=root rd.luks.options=discard root=/dev/mapper/root rootflags=subvol=@root rw"

# loglevel=3: print only 3 (KERN_ERR) conditions during boot process.
# acpi_osi=Linux: tell the motherboard's BIOS to load their ACPI tables for Linux.
# usbcore.autosuspend=-1: never auto-suspend USB devices, to prevent stuttering on wireless mice.
COMMON_PARAMS="loglevel=3 quiet add_efi_memmap acpi_osi=Linux skew_tick=1 mce=ignore_ce nowatchdog tsc=reliable no_timer_check usbcore.autosuspend=-1 ${MICROCODE:-}"

RefindBootloader() {
    # x86_64-efi: rEFInd overrides GRUB2 without issues.
    # --usedefault: required for MSI motherboards.
    refind-install --usedefault "${BOOT_DISK}"
    # Tell rEFInd to detect the initramfs for linux-lts & linux automatically.
    # Boot default entry immediately unless a key is held down.
    
    if [[ ! -a "/tmp/RefindBootloader.empty" ]]; then
        echo '
extra_kernel_version_strings "linux-lts,linux"
timeout -1' >> /boot/EFI/refind/refind.conf
        touch /tmp/RefindBootloader.empty
    fi

    \cp "${cp_flags}" "${SRC_DIR}/Files/etc/pacman.d/hooks/refind.hook" "/etc/pacman.d/hooks/"
	refind-mkdefault
}

RefindBootloaderCFG() {
    cat <<EOF >"${BOOT_CONF}"
"Boot using standard options"  "${REQUIRED_PARAMS} ${COMMON_PARAMS} ${MITIGATIONS_OFF:-}"

"Boot to single-user mode"  "single ${REQUIRED_PARAMS} ${COMMON_PARAMS} ${MITIGATIONS_OFF:-}"

"Boot with minimal options"  "${REQUIRED_PARAMS} ${MICROCODE:-} ${MITIGATIONS_OFF:-}"
EOF
}
RefindBootloader
RefindBootloaderCFG
