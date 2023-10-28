#!/bin/bash
# shellcheck disable=SC2162
set +H
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "${SCRIPT_DIR}" && GIT_DIR=$(git rev-parse --show-toplevel)
source "${GIT_DIR}/configs/settings.sh"

clear

TOTAL_RAM=$(($(getconf _PHYS_PAGES) * $(getconf PAGE_SIZE) / (1024 * 1024)))

[[ ${DEBUG} -eq 1 ]] &&
    set -x

# In-case these were mounted beforehand.
umount -flRq /mnt || :
umount -flRq /mnt/archinstall || :

cryptsetup close cleanit >&/dev/null || :
cryptsetup close root >&/dev/null || :

lsblk -o PATH,MODEL,PARTLABEL,FSTYPE,FSVER,SIZE,FSUSE%,FSAVAIL,MOUNTPOINTS

SelectDiskPrompt() {
    read -rep $'\nDisk examples: /dev/sda or /dev/nvme0n1; don\'t use partition numbers like: /dev/sda1 or /dev/nvme0n1p1.\nInput your desired disk, then press ENTER: ' -i "/dev/" DISK
    WhichDiskSelected() {
        echo -e "\n\e[1;35mSelected disk: ${DISK}\e[0m\n"
        read -p "Is this correct? [Y/N]: " choice
    }
    WhichDiskSelected
    case ${choice} in
    [Y]*)
        return 0
        ;;
    [N]*)
        SelectDiskPrompt
        ;;
    *)
        echo -e "\nInvalid option!\nValid options: Y, N"
        WhichDiskSelected
        ;;
    esac
}
SelectDiskPrompt

if [[ ${DISK} =~ "nvme" ]] || [[ ${DISK} =~ "mmc" ]]; then
    PARTITION1="${DISK}p1"
    PARTITION2="${DISK}p2"
    PARTITION3="${DISK}p3"
else
    PARTITION1="${DISK}1"
    PARTITION2="${DISK}2"
    PARTITION3="${DISK}3"
fi

RemovePartitions() {
    swapoff "${PARTITION2}" || : # Ensure swap isn't used, otherwise it cannot be deleted
    wipefs -af ${DISK}*          # Remove partition-table signatures on selected disk
    sgdisk -Z "${DISK}"          # Remove GPT & MBR data structures on selected disk
}

WipeEntireDisk() {
    read -p $'\n\nWith \'Secure\' the estimated wait time is minutes up to hours, depending on both the disk\'s type and size.\n\nSelect either Secure or Normal: ' choice
    case ${choice} in
    ["Secure"]*)
        RemovePartitions
        cryptsetup open --type plain -d /dev/urandom "${DISK}" cleanit
        ddrescue --force /dev/zero /dev/mapper/cleanit
        cryptsetup close cleanit
        ;;
    ["Normal"]*)
        RemovePartitions
        return 0
        ;;
    *)
        echo -e "\nInvalid option!\nValid options: Secure, Normal"
        WipeEntireDisk
        ;;
    esac
}
WipeEntireDisk

# Create GPT disk 2048 alignment
sgdisk -a 2048 -o "${DISK}"
# Partition 1 (UEFI boot)
sgdisk -n 1::+1024M --typecode=1:ef00 --change-name=1:'BOOTEFI' "${DISK}"
# Partition 2 (swap)
sgdisk -n 2::+"${TOTAL_RAM}"M --typecode=2:8200 "${DISK}"
# Partition 3 ("/" or "root" directory)
sgdisk -n 3::-0 --typecode=3:8300 --change-name=3:'ROOT' "${DISK}"

# Make the Linux kernel use the latest partition tables without rebooting
partprobe "${DISK}"

mkfs.fat -F 32 "${PARTITION1}"
mkswap "${PARTITION2}"

SetLUKSPasswordPrompt() {
    read -rp $'\nEnter a new password for the LUKS2 container: ' DESIREDPW
    if [[ -z ${DESIREDPW} ]]; then
        echo -e "\nNo password was entered, please try again.\n"
        SetLUKSPasswordPrompt
    fi

    read -rp $'\n\e[1;35mPlease repeat your LUKS2 password:\e[0m ' LUKS_PWCODE
    if [[ ${DESIREDPW} == "${LUKS_PWCODE}" ]]; then
        echo -n "${LUKS_PWCODE}" | cryptsetup luksFormat -M luks2 "${PARTITION3}"
        echo -n "${LUKS_PWCODE}" | cryptsetup open "${PARTITION3}" root
    else
        echo -e "\nPasswords do not match, please try again.\n"
        SetLUKSPasswordPrompt
    fi
}

SetLUKSPasswordPrompt
echo -e "\n\e[1;32mDisk formatting successful!\e[0m\n"
exit 0
