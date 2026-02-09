# Deploying Ceph and ClickHouse on Bare-Metal Kubernetes

This guide provides instructions for deploying a Ceph and ClickHouse cluster on a bare-metal Kubernetes cluster. This setup can be managed by Azure Arc for a hybrid cloud solution.

The base guide related to the Operators itself is provided in [AKS deployment guide](./aks-deployment.md).

## Overview

The project is structured into two main parts:
1.  **Operators**: Deploys the Rook/Ceph and ClickHouse operators.
2.  **Clusters**: Deploys the Ceph and ClickHouse clusters.

## Prerequisites

Before you begin, ensure you have the following:
* A running Kubernetes cluster on bare-metal servers.
* At least 3 nodes in the cluster for a production setup.
* Raw block devices available on the nodes for Ceph storage.
* [kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl/) installed and configured to connect to your cluster.
* [Terraform](https://learn.hashicorp.com/tutorials/terraform/install-cli) installed.
* [Helm](https://helm.sh/docs/intro/install/) installed.

For managing your bare-metal cluster with Azure, you can connect it to [Azure Arc](https://docs.microsoft.com/en-us/azure/azure-arc/kubernetes/overview).

## 1. Configure Storage for Ceph on Bare-Metal

For a bare-metal deployment, Rook can directly consume the block devices on the nodes. The `modules/ceph-cluster/cluster.yaml` file is already configured for this scenario.

The `storage` section in `modules/ceph-cluster/cluster.yaml` uses `deviceFilter` to select the devices to be used by Ceph.

```yaml
  storage: # cluster level storage configuration and selection
    useAllNodes: true
    useAllDevices: false
    deviceFilter: ${device_filter}
```

The `device_filter` variable is passed from the Terraform configuration. In `terraform/10_clusters/ceph-cluster.tf`, you need to set the `device_filter` to match the names of the devices you want to use for Ceph. For example, if your devices are named `sda`, `sdb`, `sdc`, you can set the `deviceFilter` to `^sd[a-z]`.

Alternatively, if you want to use all available devices on the nodes, you can set `useAllDevices: true` and remove the `deviceFilter`.

**Important:** Make sure the devices you select for Ceph are not in use and do not contain any important data, as they will be formatted by Rook.

You will need to update the `device_filter` value in `terraform/10_clusters/ceph-cluster.tf` to explicitly set it:
```terraform
module "ceph_cluster" {
    source = "${path.module}/../../modules/ceph-cluster"

    namespace     = "rook-ceph"
    cluster_name  = "base"
    device_filter = "^vd[b-c]$" # Example: set this to your desired filter
}
```

## 2. Deploy the Operators and Clusters

The deployment process is the same as for AKS.

### 2.1. Deploy the Operators

Navigate to the `terraform/01_operators` directory and run the following commands:

```bash
terraform init
terraform apply
```

This will deploy the Rook/Ceph and ClickHouse operators.

### 2.2. Deploy the Clusters

Navigate to the `terraform/10_clusters` directory and run the following commands:

```bash
terraform init
terraform apply
```

This will deploy the Ceph and ClickHouse clusters.

## 3. Connect to ClickHouse and Ceph

The instructions for connecting to ClickHouse and accessing Ceph object storage are the same as for the AKS deployment. Please refer to the [AKS deployment guide](aks-deployment.md) for details.

## 4. Scaling the Clusters

### 4.1. Scaling ClickHouse

The scaling instructions for ClickHouse are the same as for the AKS deployment.

### 4.2. Scaling Ceph

To scale the Ceph cluster, you can add new nodes with raw block devices to your Kubernetes cluster. If `useAllNodes` and `useAllDevices` are set to `true`, Rook will automatically discover the new devices and add them to the Ceph cluster.

If you are using `deviceFilter`, you need to make sure the new devices match the filter.

You can also add more disks to existing nodes. Rook will detect them and create new OSDs.
