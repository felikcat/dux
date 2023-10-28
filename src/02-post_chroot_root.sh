#!/bin/bash
set +H
set -e

SRC_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SRC_DIR}/GLOBAL_IMPORTS.sh"
source "${SRC_DIR}/Configs/settings.sh"

clear

CPU_VENDOR=$(grep -m1 'vendor' /proc/cpuinfo | cut -f2 -d' ')
# Also covers GCC's -mtune
MARCH=$(gcc -march=native -Q --help=target | grep -oP '(?<=-march=).*' -m1 | awk '{$1=$1};1')
# Caches result of 'nproc'
NPROC=$(nproc)

Preparation() {
	pacman -Sy --quiet --noconfirm --ask=4 archlinux-keyring && pacman -Su --quiet --noconfirm --ask=4

	sed -i '/^#en_US.UTF-8 UTF-8/s/^#//' /etc/locale.gen
	locale-gen

	local TZ
	TZ=$(curl -s http://ip-api.com/line?fields=timezone)
	systemd-firstboot --keymap="${system_keymap}" --timezone="${TZ}" --locale="en_US.UTF-8" --hostname="${system_hostname}" --setup-machine-id --force || :

	# Use the new locale.conf now to stop 'perl' from complaining about a broken locale.
	unset LANG
	source /etc/profile.d/locale.sh
	hwclock --systohc

	cat <<EOF >/etc/hosts
# Static table lookup for hostnames.
# See hosts(5) for details.

127.0.0.1        localhost
::1              ip6-localhost
127.0.1.1        ${system_hostname}
EOF

	# Safe to do; if say /home/admin existed, it wouldn't also remove /home/admin.
	if id -u "${YOUR_USER}" >/dev/null 2>&1; then
		userdel "${YOUR_USER}"
	fi

	# gamemode: Allows for maximum performance while a specific program is running.
	groupadd --force -g 385 gamemode

	# Why 'video': https://github.com/Hummer12007/brightnessctl/issues/63
	useradd -m -G users,wheel,video,gamemode -s /bin/zsh "${YOUR_USER}" &&
		echo "${YOUR_USER}:${PWCODE}" | chpasswd

	# Useful for the Trinity Control Center which isn't used; kept here for more programs to work correctly.
	useradd -s /bin/zsh root || :
        echo "root:${PWCODE}" | chpasswd
	unset PWCODE

	# sudo: Allow users in group 'wheel' to elevate to superuser without prompting for a password (until 04-finalize.sh).
	echo "%wheel ALL=(ALL) NOPASSWD: ALL" >/etc/sudoers.d/custom_settings

	# Backup Dux before proceeding.
	mv -f "/home/${YOUR_USER}/dux" "/home/${YOUR_USER}/dux_backup_${DATE}" >&/dev/null || :
	\cp "${cp_flags}" -R "${SRC_DIR}" "/home/${YOUR_USER}/dux"

	# Ensure these directories exist.
	mkdir "${mkdir_flags}" {/etc/{modules-load.d,NetworkManager/conf.d,modprobe.d,tmpfiles.d,pacman.d/hooks,X11,fonts,systemd/coredump.conf.d,snapper/configs,conf.d},/boot,/home/"${YOUR_USER}"/.config/{fontconfig/conf.d,systemd/user},/usr/share/libalpm/scripts}
}
Preparation

# ${MARCH}: Optimize for current CPU generation.
# RUSTFLAGS: Same reason as the above.
# ${NPROC}: Ensure multi-threading to drastically lower compilation times for PKGBUILDs.
# pbzip2, pigz: Multi-threaded replacements for: bzip2, gzip.
sed -i -e "s/-march=x86-64 -mtune=generic/-march=${MARCH} -mtune=${MARCH}/" \
	-e 's/.RUSTFLAGS.*/RUSTFLAGS="-C opt-level=2 -C target-cpu=native"/' \
	-e "s/.MAKEFLAGS.*/MAKEFLAGS=\"-j${NPROC} -l${NPROC}\"/" \
	-e "s/xz -c -z -/xz -c -z -T ${NPROC} -/" \
	-e "s/bzip2 -c -f/pbzip2 -c -f/" \
	-e "s/gzip -c -f -n/pigz -c -f -n/" \
	-e "s/zstd -c -z -q -/zstd -c -z -q -T${NPROC} -/" \
	-e "s/lrzip -q/lrzip -q -p ${NPROC}/" /etc/makepkg.conf

# Ensure multi-threaded compiling outside of PKGBUILDs.
sed -i "s/.DefaultEnvironment.*/DefaultEnvironment=\"GNUMAKEFLAGS=-j${NPROC} -l${NPROC}\" \"MAKEFLAGS=-j${NPROC} -l${NPROC}\"/" \
	/etc/systemd/{system.conf,user.conf}

# Enable the 32-bit software repository.
sed -i "/\[multilib\]/,/Include/"'s/^#//' /etc/pacman.conf

Hardware() {
	if [[ ${hardware_wifi_and_bluetooth} -eq 1 ]]; then
		PKGS+=(iwd bluez bluez-utils)
		SERVICES+=(iwd.service bluetooth.service)
	fi

	if [[ ${hardware_printers_and_scanners} -eq 1 ]]; then
		# Also requires nss-mdns; installed by default.
		PKGS+=(cups cups-filters ghostscript gsfonts cups-pk-helper sane system-config-printer simple-scan)
		# Also requires avahi-daemon.service; enabled by default.
		SERVICES+=(cups.socket)
		ConfigCUPS() {
			chattr -f -i /etc/nsswitch.conf # Ensure file is writable.
			sed -i "s/hosts:.*/hosts: files mymachines myhostname mdns_minimal [NOTFOUND=return] resolve/" /etc/nsswitch.conf
		}
		trap ConfigCUPS EXIT
	fi
}
Hardware

# Root-less Xorg to lower its memory usage and increase overall security.
\cp "${cp_flags}" "${SRC_DIR}"/Files/etc/X11/Xwrapper.config "/etc/X11/"

# Tells mlocate to ignore Snapper's Btrfs snapshots; avoids slowdowns and excessive memory usage.
if [[ ! -a "/tmp/UpdateDB.empty" ]]; then
	echo 'PRUNENAMES = ".snapshots"' >>/etc/updatedb.conf
	touch /tmp/UpdateDB.empty
fi

# Default packages, regardless of options selected.
PKGS+=(refind
irqbalance power-profiles-daemon thermald dbus-broker gamemode lib32-gamemode iptables-nft
chrony dnsmasq openresolv libnewt pigz pbzip2 strace usbutils linux-firmware gnome-keyring avahi nss-mdns
man-db man-pages pacman-contrib mkinitcpio bat
wget trash-cli reflector rebuild-detector vim)

case $(systemd-detect-virt) in
"none")
	if [[ ${CPU_VENDOR} = "AuthenticAMD" ]]; then
		PKGS+=(amd-ucode)
		MICROCODE="initrd=amd-ucode.img initrd=initramfs-%v.img"
	elif [[ ${CPU_VENDOR} = "GenuineIntel" ]]; then
		PKGS+=(intel-ucode)
		MICROCODE="initrd=intel-ucode.img initrd=initramfs-%v.img"
	fi
	;;
"kvm")
	PKGS+=(qemu-guest-agent)
	;;
"vmware")
	PKGS+=(open-vm-tools gtkmm3)
	# Our vmware-user.service is created then enabled in 05-booted.sh
	SERVICES+=(vmtoolsd.service vmware-vmblock-fuse.service)
	;;
"oracle")
	PKGS+=(virtualbox-guest-utils)
	SERVICES+=(vboxservice.service)
	;;
"microsoft")
	PKGS+=(hyperv)
	SERVICES+=(hv_fcopy_daemon.service hv_kvp_daemon.service hv_vss_daemon.service)
	;;
*)
	printf "\nWARNING: Your virtualization environment or CPU vendor is not supported.\n"
	;;
esac

# -Syuu (double -u) to start using the multilib repo now.
pacman -Syuu --quiet --noconfirm --ask=4 --needed "${PKGS[@]}"

# Prevents many unnecessary initramfs generations to speed up the install process drastically.
ln -sf /dev/null /usr/share/libalpm/hooks/60-mkinitcpio-remove.hook
ln -sf /dev/null /usr/share/libalpm/hooks/90-mkinitcpio-install.hook

# Prevent instability if any program attempts to bruteforce your login's password.
if [[ ! -a "/tmp/FailLock.empty" ]]; then
	echo 'deny = 0' >> /etc/security/faillock.conf
	touch /tmp/FailLock.empty
fi

# Default services, regardless of options selected.
# rfkill-unblock@all: Ensure Wi-Fi & Bluetooth aren't soft blocked on startup.
SERVICES+=(fstrim.timer btrfs-scrub@-.timer
irqbalance.service dbus-broker.service power-profiles-daemon.service thermald.service avahi-daemon.service chronyd.service
rfkill-unblock@all)

systemctl enable "${SERVICES[@]}"

# systemd devs make fixes to problems that don't matter to others, and half-ass some of their solutions -- such as resolved.
# Good arguments pointing out systemd's flaws: https://skarnet.org/software/systemd.html & https://forums.gentoo.org/viewtopic-t-1105854.html
systemctl mask lvm2-lvmpolld.socket lvm2-monitor.service systemd-resolved.service systemd-oomd.service systemd-timedated.service systemd-timesyncd.service systemd-networkd.service

# GRUB2 is replacing rEFInd later on.
#source "${SRC_DIR}/Install_GRUB.sh"
source "${SRC_DIR}/Install_rEFInd.sh"

# Ensure "net.ipv4.tcp_congestion_control = bbr" is a valid option.
\cp "${cp_flags}" "${SRC_DIR}"/Files/etc/modules-load.d/tcp_bbr.conf "/etc/modules-load.d/"

# Configures various kernel parameters.
\cp "${cp_flags}" "${SRC_DIR}/Files/etc/sysctl.d/99-custom.conf"  "/etc/sysctl.d/"
\cp "${cp_flags}" "${SRC_DIR}/Files/etc/sysfs.conf" 			  "/etc/"

# Use overall best I/O scheduler for each drive type (NVMe, SSD, HDD).
\cp "${cp_flags}" "${SRC_DIR}/Files/etc/udev/rules.d/60-io-schedulers.rules" "/etc/udev/rules.d/"

# https://wiki.archlinux.org/title/zsh#On-demand_rehash
\cp "${cp_flags}" "${SRC_DIR}/Files/etc/pacman.d/hooks/zsh.hook" "/etc/pacman.d/hooks/"

# The kernel's core dump handling is disabled by our sysctl config, inform systemd of it as well.
\cp "${cp_flags}" "${SRC_DIR}/Files/etc/systemd/coredump.conf.d/99-custom.conf" "/etc/systemd/coredump.conf.d"

\cp "${cp_flags}" "${SRC_DIR}/Files/etc/xdg/reflector/reflector.conf" "/etc/xdg/reflector/" &&
    sed -i "s/~02-post_chroot_root~/${reflector_countrylist}/" /etc/xdg/reflector/reflector.conf

Prepare03() {
	chmod +x -R {/home/"${YOUR_USER}"/dux,/home/"${YOUR_USER}"/dux_backup_"${DATE}"} >&/dev/null || :
	chown -R "${YOUR_USER}:${YOUR_USER}" "/home/${YOUR_USER}"
}
trap Prepare03 EXIT
