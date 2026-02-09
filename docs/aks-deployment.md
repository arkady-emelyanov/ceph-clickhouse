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

First, you need to create an AKS cluster. Cluster with at least 3 nodes to accommodate the Ceph and ClickHouse components is recommended.

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

provider "kubectl" {
  host                   = data.azurerm_kubernetes_cluster.aks_data.kube_config.0.host
  client_certificate     = base64decode(data.azurerm_kubernetes_cluster.aks_data.kube_config.0.client_certificate)
  client_key             = base64decode(data.azurerm_kubernetes_cluster.aks_data.kube_config.0.client_key)
  cluster_ca_certificate = base64decode(data.azurerm_kubernetes_cluster.aks_data.kube_config.0.cluster_ca_certificate)
  load_config_file       = false  
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

Configuration:

* [ClickHouse Operator](https://docs.altinity.com/altinitykubernetesoperator/kubernetesoperatorguide/clickhouseoperatorsettings/)
* [ClickHouse cluster](https://docs.altinity.com/altinitykubernetesoperator/kubernetesoperatorguide/clustersettings/)
* [Rook Operator](https://rook.io/docs/rook/latest-release/Getting-Started/quickstart/#deploy-the-rook-operator)
* [Ceph ObjectStorage](https://rook.io/docs/rook/latest-release/Storage-Configuration/Object-Storage-RGW/object-storage/#configure-an-object-store)
* [Ceph BucketClaim](https://rook.io/docs/rook/latest-release/Storage-Configuration/Object-Storage-RGW/ceph-object-bucket-claim/)


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

First, find the toolbox pod name (toolbox uses name of the cluster as app name, in this case `base`):
```bash
kubectl get pods -n rook-ceph -l app=base
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

Sample output:

```
$ kubectl -n rook-ceph exec -it base-5dd66fd5f4-72x28 -- bash
bash-5.1$ ceph status
  cluster:
    id:     88c73e47-5e63-4823-8852-8579db12e74d
    health: HEALTH_OK
 
  services:
    mon: 3 daemons, quorum a,b,c (age 107m)
    mgr: a(active, since 106m), standbys: b
    osd: 3 osds: 3 up (since 9h), 3 in (since 9h)
    rgw: 1 daemon active (1 hosts, 1 zones)
 
  data:
    pools:   9 pools, 185 pgs
    objects: 386 objects, 483 KiB
    usage:   198 MiB used, 17 GiB / 18 GiB avail
    pgs:     185 active+clean
 
bash-5.1$ ceph osd status
ID  HOST           USED  AVAIL  WR OPS  WR DATA  RD OPS  RD DATA  STATE      
 0  minikube      60.0M  5941M      0        0       0        0   exists,up  
 1  minikube-m02  77.6M  5923M      0        0       0        0   exists,up  
 2  minikube-m03  60.0M  5941M      0        0       1        0   exists,up  

```

## 5. Connect to ClickHouse

**Note:** ClickHouse operator uses [ClickHouse Keeper](https://clickhouse.com/docs/guides/sre/keeper/clickhouse-keeper) implementation
instead of Apache ZooKeeper.

To connect to the ClickHouse cluster, you can use the `DBeaver`. To get the credentials, query the clickhouse credentials secret
(please note, default user has no password by default).

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

Increasing `shardsCount` adds more shards to the cluster. Operation does not rebalance data, only new data will benefit from scaling. See [ClickHouse recommendations](https://clickhouse.com/docs/guides/sre/scaling-clusters) about data rebalance strategy.

### 7.2. Scaling Ceph

To scale the Ceph cluster, you can increase the `count` in the `storageClassDeviceSets` in `modules/ceph-cluster/cluster.yaml` and re-run `terraform apply` in the `terraform/10_clusters` directory. This will provision new OSDs. Ceph will automatically rebalance cluster. See [Ceph Balancer documentation](https://cephdocs.readthedocs.io/en/stable/rados/operations/balancer/) for more details.

To add new OSD node to cluster increase `count` in the `storageClassDeviceSets` section.
