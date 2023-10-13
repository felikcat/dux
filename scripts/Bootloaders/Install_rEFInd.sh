#!/bin/bash
set +H
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "${SCRIPT_DIR}" && GIT_DIR=$(git rev-parse --show-toplevel)
source "${GIT_DIR}/scripts/GLOBAL_IMPORTS.sh"
source "${GIT_DIR}/configs/settings.sh"

BOOT_DISK=$(blkid -s PARTLABEL -s PARTUUID | sed -n '/"BOOTEFI"/p' | cut -f1 -d':')

# loglevel=3: print only 3 (KERN_ERR) conditions during boot process.
# acpi_osi=Linux: tell the motherboard's BIOS to load their ACPI tables for Linux.
COMMON_PARAMS="loglevel=3 quiet add_efi_memmap acpi_osi=Linux skew_tick=1 mce=ignore_ce nowatchdog tsc=reliable no_timer_check ${MICROCODE:-}"

RefindBootloader() {
    # x86_64-efi: rEFInd overrides GRUB2 without issues.
    # --usedefault: required for MSI motherboards.
    refind-install --usedefault "${BOOT_DISK}"
    # Tell rEFInd to detect the initramfs for linux-lts & linux automatically.
    # Boot default entry immediately unless a key is held down.
    sed -i -e 's/^#extra_kernel_version_strings.*/extra_kernel_version_strings "linux-lts,linux"/' \
        -e "s/timeout 20/timeout -1/" /boot/EFI/refind/refind.conf

    \cp "${cp_flags}" "${GIT_DIR}"/files/etc/pacman.d/hooks/refind.hook "/etc/pacman.d/hooks/"
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

