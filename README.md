# Ceph and ClickHouse on Kubernetes

This project provides Terraform and Helm configurations to deploy a Ceph and ClickHouse cluster on Kubernetes.

## Implementation notes

Scripts `01_create-disks.sh`, `10_create-minikube.sh` and `20_mount-disks` are only applicable to the Minikube target.

## Documentation

* [ClickHouse Operator](https://altinity.com/kubernetes-operator/)
* [Ceph Operator](https://rook.io/docs/rook/latest-release/Getting-Started/intro/)


## Environments

This repository contains instructions for deploying the project on different environments:

*   [Deploying on Minikube Kubernetes](docs/minikube-deployment.md)
*   [Deploying on Azure Kubernetes Service (AKS)](docs/aks-deployment.md)
*   [Deploying on Bare-Metal Kubernetes](docs/bare-metal-deployment.md)

Please refer to the respective guides for detailed instructions.
