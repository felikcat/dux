#!/bin/bash

# Accepts multiple ranges, such as: C0-3,9-12
VM_CORES="~virtual_machines.sh~"
HOST_CORES="~virtual_machines.sh~"

if [[ "$2/$3" = "prepare/begin" ]]; then
    vfio-isolate cpuset-create --cpus "${HOST_CORES}" /host.slice
    vfio-isolate cpuset-create --cpus "${VM_CORES}" -nlb /machine.slice
    vfio-isolate move-tasks / /host.slice

    vfio-isolate -u /tmp/undo-gov cpu-governor performance "${VM_CORES}"
    vfio-isolate vfio-isolate -u /tmp/undo-irq irq-affinity mask "${VM_CORES}"
fi

if [[ "$2/$3" = "release/end" ]]; then
    vfio-isolate cpuset-delete /host.slice
    vfio-isolate cpuset-delete /machine.slice
    vfio-isolate restore /tmp/undo-gov
    vfio-isolate restore /tmp/undo-irq
fi
