# Deploying on Minikube

This guide provides instructions for deploying the Ceph and ClickHouse cluster on a local Minikube environment.

The base guide related to the Operators itself is provided in [AKS deployment guide](./aks-deployment.md).

## Prerequisites

* Minikube installed and configured.
* `kubectl` installed.
* `helm` installed.
* `terraform` installed.
* Sufficient resources (CPU, Memory, Disk) allocated to your Minikube instance. A suggested Minikube configuration for this deployment is:
    * **CPUs:** 2
    * **Memory:** 8GB
    * **Disk:** 10GB (This will be in addition to the disks created by `01_create-disks.sh`)
    * You can configure Minikube resources using commands like:
      ```bash
      minikube config set cpus 2
      minikube config set memory 8192
      minikube config set disk-size 10g
      ```

## Minikube Setup

The project includes scripts to set up Minikube and provision local disks for Ceph.

### 1. Create Disks

This script creates sparse files that will be used as physical volumes by Ceph.

```bash
./01_create-disks.sh
```

### 2. Create Minikube Cluster

This script initializes a Minikube cluster. Ensure Minikube drivers are correctly configured for your environment.

```bash
./10_create-minikube.sh
```

### 3. Mount Disks to Minikube

This script mounts the previously created sparse files as disks into the Minikube virtual machine.

```bash
./20_mount-disks.sh
```

## Deployment Steps (Terraform & Helm)

The following steps will deploy the Ceph and ClickHouse operators, and then the Ceph and ClickHouse clusters using Terraform.


### 1. Deploy Operators

Navigate to the operators' Terraform directory and apply the configuration. This will deploy the Rook Ceph operator and the Altinity ClickHouse operator.

```bash
cd terraform/01_operators
terraform init
terraform apply -auto-approve
cd ../..
```

### 2. Deploy Ceph and ClickHouse Clusters

Navigate to the clusters' Terraform directory and apply the configuration. This will provision the Ceph cluster and a ClickHouse cluster.

```bash
cd terraform/10_clusters
terraform init
terraform apply -auto-approve
cd ../..
```

## Verification

After applying the Terraform configurations, you can verify the deployment status.

### 1. Check Kubernetes Pods

Ensure all pods in the `rook-ceph` and `clickhouse-system` namespaces are running.

```bash
kubectl get pods -n rook-ceph
kubectl get pods -n clickhouse-system
```

### 2. Check Ceph Cluster Health

Access the `rook-ceph-tools` pod to run Ceph commands and verify the cluster's health.

```bash
# Get the name of the rook-ceph-tools pod
ROOK_TOOLS_POD=$(kubectl get pod -l "app=base" -n rook-ceph -o jsonpath='{.items[0].metadata.name}')

# Execute ceph status command
kubectl exec -it $ROOK_TOOLS_POD -n rook-ceph ceph status

# Execute ceph osd tree command
kubectl exec -it $ROOK_TOOLS_POD -n rook-ceph ceph osd tree
```
Expected output for `ceph status` should show "HEALTH_OK".

### 3. Check ClickHouse Cluster Status

Verify the ClickHouse instances are running and accessible.

```bash
kubectl get pods -l "app.kubernetes.io/name=clickhouse" -n clickhouse-system
```

You can also port-forward to a ClickHouse instance to connect to it:

```bash
# Get the name of a ClickHouse client pod (adjust label if needed)
CH_CLIENT_POD=$(kubectl get pod -l clickhouse.altinity.com/cluster=clickhouse -n clickhouse-system -o jsonpath='{.items[0].metadata.name}')

# Port forward to the ClickHouse client
kubectl port-forward $CH_CLIENT_POD 8123:8123 &

# You can now access ClickHouse on localhost:8123
```
