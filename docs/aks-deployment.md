# Deploying Ceph and ClickHouse on Azure Kubernetes Service (AKS)

This guide provides instructions for deploying a Ceph and ClickHouse cluster on Azure Kubernetes Service (AKS) using Terraform and Helm.

## Overview

The project is structured into two main parts:
1.  **Operators**: Deploys the Rook/Ceph and ClickHouse operators.
2.  **Clusters**: Deploys the Ceph and ClickHouse clusters.

The infrastructure is managed by Terraform, and the ClickHouse cluster is deployed using a Helm chart.

## Prerequisites

Before you begin, ensure you have the following tools installed:
*   [Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli)
*   [kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl/)
*   [Terraform](https://learn.hashicorp.com/tutorials/terraform/install-cli)
*   [Helm](https://helm.sh/docs/intro/install/)

You also need an active Azure subscription.

## 1. Create an AKS Cluster

First, you need to create an AKS cluster. We recommend using a cluster with at least 3 nodes of size `Standard_D4s_v3` to accommodate the Ceph and ClickHouse components.

You can create an AKS cluster using the Azure CLI:

```bash
# Set your variables
RESOURCE_GROUP="my-aks-rg"
CLUSTER_NAME="my-aks-cluster"
LOCATION="eastus"

# Create a resource group
az group create --name $RESOURCE_GROUP --location $LOCATION

# Create the AKS cluster
az aks create \
    --resource-group $RESOURCE_GROUP \
    --name $CLUSTER_NAME \
    --node-count 3 \
    --node-vm-size Standard_D4s_v3 \
    --enable-managed-identity \
    --generate-ssh-keys

# Get the credentials for your new cluster
az aks get-credentials --resource-group $RESOURCE_GROUP --name $CLUSTER_NAME
```

## 2. Configure Storage for Ceph on AKS

The default Ceph configuration in this repository is designed for bare-metal or VM deployments using `hostPath` and `deviceFilter`. For AKS, we need to use Azure Managed Disks. Rook can provision OSDs on top of PVCs using `storageClassDeviceSets`.

You will need to modify the `modules/ceph-cluster/cluster.yaml` file to use `storageClassDeviceSets`.

First, create a `StorageClass` that uses Azure Managed Disks. You can use the default `managed-premium` storage class provided by Azure, or create a new one.

Then, update the `storage` section in `modules/ceph-cluster/cluster.yaml` to look like this:

```yaml
  storage:
    storageClassDeviceSets:
    - name: set1
      count: 3
      portable: false
      tuneDeviceClass: true
      volumeClaimTemplates:
      - metadata:
          name: data
        spec:
          resources:
            requests:
              storage: 1024Gi
          storageClassName: managed-premium
          volumeMode: Block
          accessModes:
            - ReadWriteOnce
```

This configuration will create 3 OSDs, each with a 1024Gi managed disk. The `count` should be equal to the number of nodes in your AKS cluster.

**Note:** This change needs to be applied to the `cluster.yaml` file before running Terraform. The `device_filter` variable in `terraform/10_clusters/ceph-cluster.tf` is not used in this AKS setup.

## 3. Deploy the Operators and Clusters

The Terraform configuration is split into two layers: `01_operators` and `10_clusters`.

### 3.1. Deploy the Operators

Navigate to the `terraform/01_operators` directory and run the following commands:

```bash
terraform init
terraform apply
```

This will deploy the Rook/Ceph and ClickHouse operators.

### 3.2. Deploy the Clusters

Navigate to the `terraform/10_clusters` directory and run the following commands:

```bash
terraform init
terraform apply
```

This will deploy the Ceph and ClickHouse clusters.

## 4. Using the Ceph Toolbox

A Ceph toolbox pod is deployed with the Ceph cluster. You can use it to run Ceph commands.

First, find the toolbox pod name:
```bash
kubectl get pods -n rook-ceph -l app=rook-ceph-tools
```

Then, exec into the toolbox pod:
```bash
kubectl -n rook-ceph exec -it <toolbox-pod-name> -- bash
```

Now you can run Ceph commands, for example:
```bash
ceph status
ceph osd status
```

## 5. Connect to ClickHouse

To connect to the ClickHouse cluster, you can use the `clickhouse-client`. First, get the service name of the ClickHouse cluster:

```bash
kubectl get services -n clickhouse-system
```

You should see a service named `clickhouse-clickhouse`. You can then port-forward to this service to connect from your local machine:

```bash
kubectl port-forward service/clickhouse-clickhouse 9000:9000 -n clickhouse-system &
clickhouse-client --host 127.0.0.1
```

## 6. Access Ceph Object Storage

The Ceph cluster is configured with an S3-compatible object store. To access it, you need to get the access key and secret key from the `rook-ceph-rgw-base-key` secret in the `rook-ceph` namespace.

```bash
kubectl -n rook-ceph get secret rook-ceph-rgw-base-key -o jsonpath="{.data.access_key}" | base64 --decode
kubectl -n rook-ceph get secret rook-ceph-rgw-base-key -o jsonpath="{.data.secret_key}" | base64 --decode
```

You also need the S3 endpoint. You can get it by looking at the `rook-ceph-rgw-base` service in the `rook-ceph` namespace:

```bash
kubectl get service rook-ceph-rgw-base -n rook-ceph
```

You can then use an S3 client like `s3cmd` or the AWS CLI to connect to the object store.

## 7. Scaling the Clusters

### 7.1. Scaling ClickHouse

To scale the ClickHouse cluster, you can modify the `shardsCount` and `replicasCount` values in `modules/clickhouse-cluster/clickhouse-cluster.tf` and re-run `terraform apply` in the `terraform/10_clusters` directory.

**Scale-out:**
Increase the `shardsCount` to add more shards to the cluster.

**Scale-in:**
Decrease the `shardsCount`. Note that you need to manually move the data from the shards that are being removed.

### 7.2. Scaling Ceph

To scale the Ceph cluster, you can increase the `count` in the `storageClassDeviceSets` in `modules/ceph-cluster/cluster.yaml` and re-run `terraform apply` in the `terraform/10_clusters` directory. This will provision new OSDs.

**Scale-out:**
Increase the `count` in the `storageClassDeviceSets`.

**Scale-in:**
Decreasing the `count` is not recommended as it can lead to data loss. You should first decommission the OSDs properly using the Ceph toolbox.

## 8. Cleanup

To remove all the resources created in this guide, you can run `terraform destroy` in the `terraform/10_clusters` and `terraform/01_operators` directories.

```bash
# Destroy the clusters
cd terraform/10_clusters
terraform destroy

# Destroy the operators
cd ../01_operators
terraform destroy
```

Finally, you can delete the AKS cluster and the resource group:

```bash
az aks delete --resource-group $RESOURCE_GROUP --name $CLUSTER_NAME
az group delete --name $RESOURCE_GROUP
```

## 9. Minikube vs AKS

This repository was originally designed for a Minikube environment. The main differences when deploying to AKS are:

*   **Storage**: Minikube uses `hostPath` and local disks, while AKS uses Azure Managed Disks. The `cluster.yaml` file needs to be modified to use `storageClassDeviceSets` instead of `deviceFilter`.
*   **Scripts**: The shell scripts in the root of the repository (`01_create-disks.sh`, `10_create-minikube.sh`, `20_mount-disks.sh`) are specific to the Minikube setup and are not used for the AKS deployment.
*   **Networking**: In AKS, services of type `LoadBalancer` will automatically provision an Azure Load Balancer. This might be relevant for exposing the Ceph RGW endpoint or the ClickHouse service.
