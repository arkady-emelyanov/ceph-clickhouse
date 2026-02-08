#!/usr/bin/env bash
set -euo pipefail

# Create disk images for minikube VMs
# They will be used by Ceph as storage devices

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &> /dev/null && pwd)
DISKS_DIR="${SCRIPT_DIR}/disks"
 
mkdir -p "${DISKS_DIR}"

# disk must be more than 5000MB to be used by Ceph
qemu-img create -f qcow2 ${DISKS_DIR}/minikube-01.qcow2 6000M -o preallocation=full
qemu-img create -f qcow2 ${DISKS_DIR}/minikube-02.qcow2 6000M -o preallocation=full
qemu-img create -f qcow2 ${DISKS_DIR}/minikube-03.qcow2 6000M -o preallocation=full

