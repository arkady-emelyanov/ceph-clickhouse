#!/usr/bin/env bash
set -euo pipefail

# check the VMs are running
# virsh list --all

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &> /dev/null && pwd)
DISKS_DIR="${SCRIPT_DIR}/disks"

DEVICE_NAME="vdb"

virsh attach-disk \
    --domain minikube ${DISKS_DIR}/minikube-01.qcow2 \
    --target ${DEVICE_NAME} --persistent --config --live

virsh attach-disk \
    --domain minikube-m02 ${DISKS_DIR}/minikube-02.qcow2 \
    --target ${DEVICE_NAME} --persistent --config --live

virsh attach-disk \
    --domain minikube-m03 ${DISKS_DIR}/minikube-03.qcow2 \
    --target ${DEVICE_NAME} --persistent --config --live

echo "Disks attached. Restarting minikube to recognize them..."
minikube stop
minikube start

echo "Disks mounted to minikube VMs."
echo "Checking block device exists in VM..."
minikube ssh --node minikube "lsblk | grep ${DEVICE_NAME}"
