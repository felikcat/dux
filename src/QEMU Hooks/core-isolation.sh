#!/bin/bash
guest_name="$1"
command="$2"

#== CPU Isolation ==#
# Name of the Virtual Machine.
VM_NAME="win10"
# Cores left after allocation to the VM.
AFTER_VM_CORES="16-19"
# Amount of total cores to allocate back after the VM is exited.
ALL_CORES="0-19"

if [[ "${command}" = "started" ]] && [[ "${guest_name}" = "${VM_NAME}" ]]; then
    systemctl set-property --runtime -- system.slice AllowedCPUs="${AFTER_VM_CORES}"
    systemctl set-property --runtime -- user.slice AllowedCPUs="${AFTER_VM_CORES}"
    systemctl set-property --runtime -- init.scope AllowedCPUs="${AFTER_VM_CORES}"
elif [[ "${command}" = "release" ]] && [[ "${guest_name}" = "${VM_NAME}" ]]; then
    systemctl set-property --runtime -- system.slice AllowedCPUs="${ALL_CORES}"
    systemctl set-property --runtime -- user.slice AllowedCPUs="${ALL_CORES}"
    systemctl set-property --runtime -- init.scope AllowedCPUs="${ALL_CORES}"
fi
