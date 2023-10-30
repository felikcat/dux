#!/bin/bash
set +H
set -e

SRC_DIR=$(dirname "$(realpath -s "${BASH_SOURCE[0]}")")
source "${SRC_DIR}/GLOBAL_IMPORTS.sh"
source "${SRC_DIR}/Configs/settings.sh"

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
