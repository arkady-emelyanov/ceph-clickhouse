locals {
  host_directory = "/var/lib/rook-${var.cluster_name}-${var.namespace}"
  storage_class_name = "${var.cluster_name}-${var.namespace}"
}

# Deploys the Ceph cluster itself. This includes the Ceph monitors, managers,
# and OSDs (Object Storage Daemons). The cluster.yaml file is a template
# that defines the Ceph cluster custom resource.
resource "kubectl_manifest" "cluster" {
  yaml_body = templatefile("${path.module}/cluster.yaml", {
    cluster_name      = var.cluster_name
    cluster_namespace = var.namespace
    device_filter     = var.device_filter
    data_dir_host_path = local.host_directory
  })
}

# Creates a StorageClass that allows Kubernetes to dynamically provision
# persistent volumes from the Ceph cluster.
resource "kubectl_manifest" "storage_class" {
  depends_on = [
    kubectl_manifest.cluster,
  ]

  yaml_body = templatefile("${path.module}/storage-class.yaml", {
    storage_class_name = local.storage_class_name
    cluster_name       = var.cluster_name
    cluster_namespace  = var.namespace
  })
}

# Creates a Ceph Object Store (RGW - RADOS Gateway) which provides an
# S3-compatible object storage service.
resource "kubectl_manifest" "object_store" {
  depends_on = [
    kubectl_manifest.cluster,
    kubectl_manifest.storage_class,
  ]

  yaml_body = templatefile("${path.module}/object-store.yaml", {
    cluster_name      = var.cluster_name
    cluster_namespace = var.namespace
  })
}

# Deploys the Rook Ceph toolbox, which is a container with Ceph client
# tools that can be used to manage the Ceph cluster.
resource "kubectl_manifest" "toolbox" {
  depends_on = [
    kubectl_manifest.cluster,
    kubectl_manifest.storage_class,
    kubectl_manifest.object_store,
  ]

  yaml_body = templatefile("${path.module}/toolbox.yaml", {
    cluster_name      = var.cluster_name
    cluster_namespace = var.namespace
  })
}