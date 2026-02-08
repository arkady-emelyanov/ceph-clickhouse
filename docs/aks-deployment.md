# Deploying Ceph and ClickHouse on Azure Kubernetes Service (AKS)

This guide provides instructions for deploying a Ceph and ClickHouse cluster on Azure Kubernetes Service (AKS) using Terraform and Helm.

## Overview

The project is structured into two main parts:
1.  **Operators**: Deploys the Rook/Ceph and ClickHouse operators.
2.  **Clusters**: Deploys the Ceph and ClickHouse clusters.

## Prerequisites

Before you begin, ensure you have the following tools installed:
* [Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli)
* [kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl/)
* [Terraform](https://learn.hashicorp.com/tutorials/terraform/install-cli)
* [Helm](https://helm.sh/docs/intro/install/)


## 1. Create an AKS Cluster

First, you need to create an AKS cluster. Cluster with at least 3 nodes of size `Standard_D4s_v3` to accommodate the Ceph and ClickHouse components is recommended.

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

### 1.1 Configure Terraform with AKS Cluster

In order to deploy Ceph/Clickhouse to AKS, provide Kubernetes API endpoint configuration to the automation.
The configuration is defined in the `terraform/01_operators/terraform.tf` and `terraform/10_clusters/terraform.tf`.

```
# Query the AKS Cluster details
data "azurerm_kubernetes_cluster" "aks_data" {
  name                = azurerm_kubernetes_cluster.aks.name
  resource_group_name = azurerm_kubernetes_cluster.aks.resource_group_name
}

# Configure Kubernetes provider
provider "kubernetes" {
  host                   = data.azurerm_kubernetes_cluster.aks_data.kube_config.0.host
  client_certificate     = base64decode(data.azurerm_kubernetes_cluster.aks_data.kube_config.0.client_certificate)
  client_key             = base64decode(data.azurerm_kubernetes_cluster.aks_data.kube_config.0.client_key)
  cluster_ca_certificate = base64decode(data.azurerm_kubernetes_cluster.aks_data.kube_config.0.cluster_ca_certificate)
}

provider "helm" {
  kubernetes {
    host                   = data.azurerm_kubernetes_cluster.aks_data.kube_config.0.host
    client_certificate     = base64decode(data.azurerm_kubernetes_cluster.aks_data.kube_config.0.client_certificate)
    client_key             = base64decode(data.azurerm_kubernetes_cluster.aks_data.kube_config.0.client_key)
    cluster_ca_certificate = base64decode(data.azurerm_kubernetes_cluster.aks_data.kube_config.0.cluster_ca_certificate)
  }
}
```

## 2. Configure Storage for Ceph on AKS

The default Ceph configuration in this repository is designed for bare-metal or VM deployments using `hostPath` and `deviceFilter`. For AKS, we need to use Azure Managed Disks. Rook can provision OSDs on top of PVCs using [storageClassDeviceSets](https://rook.io/docs/rook/v1.9/CRDs/ceph-cluster-crd/?h=devicefilter#pvc-based-cluster)

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
**Note on `device_filter`**: In the AKS setup, the `device_filter` variable (which might be present in `cluster.yaml` from other deployment types) is not used. Ensure it is removed or commented out from `cluster.yaml` when using `storageClassDeviceSets`.

This configuration will create 3 OSDs, each with a 1024Gi managed disk (the minimum disk to be considered by OSD is 5000MB). The `count` should be equal to the number of nodes in your AKS cluster.

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

To connect to the ClickHouse cluster, you can use the `DBeaver`. To get the credentials, query the clickhouse credentials secret
(please note, by default, default user is passwordless).

```bash
kubectl -n clickhouse-system get secret clickhouse-credentials -o jsonpath="{.data.user}" | base64 --decode
kubectl -n clickhouse-system get secret clickhouse-credentials -o jsonpath="{.data.password}" | base64 --decode
```

Port-forward to ClickHouse service to connect from your local machine:

```bash
kubectl port-forward service/clickhouse-clickhouse 8123:8123 -n clickhouse-system
```

Use `localhost` as ClickHouse host and `8123` as port number.


## 6. Access S3 Object Storage

The Ceph cluster is configured with an S3-compatible object store. To access it, you need to get the access key and secret key from the `warehouse` secret in the `rook-ceph` namespace. For connection details use connection parameters from `warehouse` ConfigMap.

Access keys (access and secret keys):

```bash
kubectl -n rook-ceph get secret warehouse -o jsonpath="{.data.AWS_ACCESS_KEY_ID}" | base64 --decode
kubectl -n rook-ceph get secret warehouse -o jsonpath="{.data.AWS_SECRET_ACCESS_KEY}" | base64 --decode
```

Connection details (host, port, and bucket name):

```bash
kubectl -n rook-ceph get configmap warehouse -o jsonpath="{.data.BUCKET_HOST}"
kubectl -n rook-ceph get configmap warehouse -o jsonpath="{.data.BUCKET_PORT}"
kubectl -n rook-ceph get configmap warehouse -o jsonpath="{.data.BUCKET_NAME}"
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

## 8. Minikube vs AKS

This repository was originally designed for a Minikube environment. The main differences when deploying to AKS are:

*   **Storage**: Minikube/On-premises uses `hostPath` and local disks, while AKS uses Azure Disks. The `cluster.yaml` file needs to be modified to use `storageClassDeviceSets` instead of `deviceFilter`.
*   **Scripts**: The shell scripts in the root of the repository (`01_create-disks.sh`, `10_create-minikube.sh`, `20_mount-disks.sh`) are specific to the Minikube setup and are not used for the AKS deployment.
