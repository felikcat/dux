#!/bin/bash
# shellcheck disable=SC2154
set +H

SRC_DIR=$(dirname "$(realpath -s "${BASH_SOURCE[0]}")")

export KEEP_GOING=1
source "${SRC_DIR}/GLOBAL_IMPORTS.sh"
unset KEEP_GOING

source "${SRC_DIR}/Configs/settings.sh"
source "${SRC_DIR}/Configs/software_catalog.sh"


if [[ ${IS_CHROOT} -eq 1 ]]; then
	echo -e "\nERROR: Do not run this script inside a chroot!\n"
	exit 1
fi

mkdir "${mkdir_flags}" "/home/${YOUR_USER}/.config/systemd/user"
chown -R "${YOUR_USER}:${YOUR_USER}" "/home/${YOUR_USER}/.config/systemd/user"

chmod +x -R "${SRC_DIR}"

[[ ${appimagelauncher} -eq 1 ]] &&
	PKGS_AUR+=(appimagelauncher)

[[ ${qpwgraph} -eq 1 ]] &&
	PKGS+=(qpwgraph)

if [[ ${opensnitch} -eq 1 ]]; then
	PKGS+=(opensnitch)
	SERVICES+=(opensnitchd.service)
fi

if [[ ${syncthing} -eq 1 ]]; then
	PKGS+=(syncthing)
    AutorunSyncthing() {
    	sudo -H -u "${YOUR_USER}" bash -c "systemctl --user enable syncthing.service"
  }
fi

if [[ ${dolphin} -eq 1 ]]; then
  # packagekit-qt5: Required for "Configure > Configure Dolphin > Context Menu > Download New Services".
  # meld: "Compare files" support.
	PKGS+=(kconfig ark dolphin kde-cli-tools kdegraphics-thumbnailers kimageformats qt5-imageformats ffmpegthumbs taglib openexr libjxl android-udev packagekit-qt5 packagekit-qt6 meld)
	ConfigDolphin() {
		local CONF="/home/${YOUR_USER}/.config/dolphinrc"
		kwriteconfig5 --file "${CONF}" --group "General" --key "ShowFullPath" "true"
		kwriteconfig5 --file "${CONF}" --group "General" --key "ShowSpaceInfo" "false"
		# Allow loading of larger images that are remotely located, such as on an SMB server.
		kwriteconfig5 --file "/home/${YOUR_USER}/.config/kdeglobals" --group "PreviewSettings" --key "MaximumRemoteSize" "10485760"
	}
fi

if [[ ${mpv} -eq 1 ]]; then
	PKGS+=(mpv)
	ConfigMPV() {
		_move2bkup "/home/${YOUR_USER}/.config/mpv/mpv.conf"
		mkdir -p "/home/${YOUR_USER}/.config/mpv/"
		\cp "${cp_flags}" "${SRC_DIR}/Files/home/.config/mpv/mpv.conf" "/home/${YOUR_USER}/.config/mpv/"
	}
fi

[[ ${onlyoffice} -eq 1 ]] &&
	FLATPAKS+=(org.onlyoffice.desktopeditors)

[[ ${evince} -eq 1 ]] &&
	PKGS+=(evince)

if [[ ${obs_studio} -eq 1 ]]; then
	# v4l2loopback = for Virtual Camera; a good universal way to screenshare.
	PKGS+=(obs-studio v4l2loopback-dkms)
	if hash pipewire >&/dev/null; then
		PKGS+=(pipewire-v4l2 lib32-pipewire-v4l2)
	fi
	# Autostart OBS to replicate NVIDIA ShadowPlay / AMD ReLive.
	AutorunOBS() {
		sudo -H -u "${YOUR_USER}" bash -c "\cp ${cp_flags} ${SRC_DIR}/Files/home/.config/systemd/user/obs-studio.service /home/${YOUR_USER}/.config/systemd/user/"
		sudo -H -u "${YOUR_USER}" bash -c "systemctl --user enable obs-studio.service"
	}
fi

[[ ${firefox_dev} -eq 1 ]] &&
	PKGS+=(libgnome-keyring libnotify firefox-developer-edition)

[[ ${foliate} -eq 1 ]] &&
	PKGS+=(foliate)

[[ ${qbittorrent_enhanced} -eq 1 ]] &&
	PKGS_AUR+=(qbittorrent-enhanced)

[[ ${feh} -eq 1 ]] &&
	PKGS+=(feh)

[[ ${yt_dlp} -eq 1 ]] &&
	PKGS+=(aria2 atomicparsley ffmpeg rtmpdump yt-dlp)

[[ ${evolution} -eq 1 ]] &&
	PKGS+=(evolution)

[[ ${discord} -eq 1 ]] &&
	FLATPAKS+=(com.discordapp.Discord)

[[ ${telegram} -eq 1 ]] &&
	FLATPAKS+=(org.telegram.desktop)

[[ ${task_manager} -eq 1 ]] &&
	PKGS+=(gnome-system-monitor)

if [[ ${virtual_machines} -eq 1 ]]; then
  PKGS+=(qemu-desktop libvirt virt-manager edk2-ovmf iptables-nft dnsmasq virglrenderer hwloc dmidecode usbutils swtpm)

  mkdir -p /etc/{modprobe.d,udev/rules.d}
  # qemu: If using QEMU directly is desired instead of libvirt.
  # video: Virtio OpenGL acceleration.
  # kvm: Hypervisor hardware acceleration.
  # libvirt: Access to virtual machines made through libvirt.
  usermod -a -G qemu,video,kvm,libvirt "${YOUR_USER}"

  KERNEL_PARAMS="intel_iommu=on iommu=pt"
  _modify_kernel_parameters

  # Do not use Copy-on-Write (CoW) for virtual machine disks.
  chattr +C -R "/var/lib/libvirt/images"

  \cp "${cp_flags}" "${SRC_DIR}/Files/etc/modprobe.d/custom_kvm.conf" "/etc/modprobe.d/"
  \cp "${cp_flags}" "${SRC_DIR}/Files/etc/udev/rules.d/99-qemu.rules" "/etc/udev/rules.d/"
fi

# Control Flatpak settings per application
FLATPAKS+=(com.github.tchx84.Flatseal)

_pkgs_add
_pkgs_aur_add
_flatpaks_add

systemctl enable --now "${SERVICES[@]}"

[[ ${syncthing} -eq 1 ]] && AutorunSyncthing
[[ ${dolphin} -eq 1 ]] && ConfigDolphin
[[ ${obs_studio} -eq 1 ]] && AutorunOBS
[[ ${mpv} -eq 1 ]] && ConfigMPV

# Fix permission issues
chown -R "${YOUR_USER}:${YOUR_USER}" "/home/${YOUR_USER}/.config"
