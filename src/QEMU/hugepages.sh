#!/bin/bash

# NOTE: 1048576KiB hugepage support is included, probable use cases for it
XML_PATH="/etc/libvirt/qemu/$1.xml"
# Get path to the launched guest domain.
MEM_SIZE=$(rg '<memory unit' "${XML_PATH}" | rg -oI '[[:digit:]]+')
# Get guest's memory size.
HPG_SIZE=$(rg '<page size' "${XML_PATH}" | rg -oI '[[:digit:]]+')
# Get guest's HugePage size.
HPG_PATH="/sys/devices/system/node/node0/hugepages/hugepages-${HPG_SIZE}kB"
# Define the HugePages path.
if [[ ! -d "${HPG_PATH}" ]]; then
    printf "ERROR: %s does not exist.\nIs HugePages disabled in the kernel?" "${HPG_PATH}" >&2
    exit 1
fi
if [[ "$2/$3" = "prepare/begin" ]]; then
    echo 0 >"${HPG_PATH}"/nr_hugepages
    echo never >/sys/kernel/mm/transparent_hugepage/enabled
    echo never >/sys/kernel/mm/transparent_hugepage/defrag
    case "${HPG_SIZE}" in
    "2048")
        echo 1 >/proc/sys/vm/compact_memory
        GUEST_PAGES=$(echo "${MEM_SIZE} / 2048" | bc)
        echo "${GUEST_PAGES}" >"${HPG_PATH}"/nr_hugepages
        ;;
    "1048576")
        sync
        echo 3 >/proc/sys/vm/drop_caches
        echo 1 >/proc/sys/vm/compact_memory
        GUEST_PAGES=$(echo "${MEM_SIZE} / 1048576" | bc)
        echo "${GUEST_PAGES}" >"${HPG_PATH}"/nr_hugepages
        ;;
    *)
        printf "\nERROR: HugePages type is not specified in the domain XML!\n" >&2
        exit 1
        ;;
    esac
fi
if [[ "$2/$3" = "release/end" ]]; then
    echo 0 >"${HPG_PATH}"/nr_hugepages
    echo always >/sys/kernel/mm/transparent_hugepage/enabled
    echo madvise >/sys/kernel/mm/transparent_hugepage/defrag
fi
