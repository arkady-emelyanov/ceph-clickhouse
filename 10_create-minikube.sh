#!/usr/bin/env bash
set -euo pipefail

# Create and start a minikube cluster with 3 nodes using the KVM2 driver

minikube start --nodes=3 --driver=kvm2 --memory=8192 --cpus=2
