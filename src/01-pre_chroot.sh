#!/bin/bash
set +H
set -e

if ! grep -q "'archiso'" /etc/mkinitcpio.d/linux.preset; then
	echo -e "\nERROR: Do not run this script outside of the Arch Linux ISO!\n"
	exit 1
fi

SRC_DIR=$(dirname "$(realpath -s "${BASH_SOURCE[0]}")")
source "${SRC_DIR}/GLOBAL_IMPORTS.sh"
source "${SRC_DIR}/Configs/settings.sh"

BOOT_PART=$(blkid -s PARTLABEL | sed -n '/BOOTEFI/p' | cut -f1 -d' ' | tr -d :)
SUBVOL_LIST=(root btrfs srv snapshots pkg log home)

clear

if cryptsetup status "root" | grep -q "inactive"; then
	echo -e "\nERROR: Forgot to mount the LUKS2 partition as the name 'root'?\n"
	exit 1
fi
LOCATION="/dev/mapper/root"


MakeDirs() {
	mkdir "${mkdir_flags}" /mnt/{tmp,boot,btrfs,var/{log,cache/pacman/pkg},srv,root,home}
}

# If the Btrfs filesystem doesn't exist on the "root" partition, create it.
if [[ ${MOUNT_ONLY} -ne 1 ]]; then
	if ! lsblk -o FSTYPE "${LOCATION}" | grep -q "btrfs"; then
		umount -flRq /mnt || :
		mkfs.btrfs "${LOCATION}" || :
		mount -t btrfs "${LOCATION}" /mnt

		MakeDirs
		mount -t vfat -o nodev,nosuid,noexec "${BOOT_PART}" /mnt/boot

		CreateSubVolumes() {
			for subvols in "${SUBVOL_LIST[@]}"; do
				btrfs subvolume create /mnt/@"${subvols}" || :
			done
		}
		CreateSubVolumes
	fi
fi
MountPartitions() {
	umount -flRq /mnt || :

	# Why 'noatime': https://archive.is/wjH73
	local OPTS="noatime,compress=zstd:1"

	mount -t btrfs -o "${OPTS}",subvol=@root "${LOCATION}" /mnt &&
		MakeDirs # Incase one of these directories was removed.

	mount -t vfat -o nodev,nosuid,noexec "${BOOT_PART}" /mnt/boot

	mount -t btrfs -o "${OPTS}",subvolid=5 "${LOCATION}" /mnt/btrfs
	mount -t btrfs -o "${OPTS}",subvol=@srv "${LOCATION}" /mnt/srv
	mount -t btrfs -o "${OPTS}",subvol=@pkg "${LOCATION}" /mnt/var/cache/pacman/pkg
	mount -t btrfs -o "${OPTS}",subvol=@log "${LOCATION}" /mnt/var/log
	mount -t btrfs -o "${OPTS}",subvol=@home "${LOCATION}" /mnt/home
}

if [[ ${MOUNT_ONLY} -eq 1 ]]; then
	MountPartitions
	echo -e "\nEntering chroot...\n"
	arch-chroot /mnt /bin/zsh
	exit 0
else
	MountPartitions
fi

# Account for Pacman suddenly exiting (due to the user sending SIGINT by pressing Ctrl + C).
rm -f /mnt/var/lib/pacman/db.lck &&
	# Install packages later if possible; keep this list minimal.
	pacstrap /mnt cryptsetup dosfstools btrfs-progs base base-devel git \
		zsh grml-zsh-config --quiet --noconfirm --ask=4 --needed

cat <<'EOF' >/mnt/etc/fstab
# Static information about the filesystems.
# See fstab(5) for details.

# <file system> <dir> <type> <options> <dump> <pass>
EOF
genfstab -U /mnt >>/mnt/etc/fstab

sed -i -e 's/^#Color/Color/' \
	-e '/^#ParallelDownloads/s/^#//' /mnt/etc/pacman.conf

# Keep DNS resolving functional if the installer was ran more than once.
ln -sf ../run/systemd/resolve/stub-resolv.conf /etc/resolv.conf
