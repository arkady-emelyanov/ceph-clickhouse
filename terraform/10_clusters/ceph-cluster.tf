# Deploys the Ceph cluster itself.
# This module uses the 'ceph-cluster' module to provision a Ceph cluster
# with a specific name, namespace, and device filter for OSDs.
module "ceph_cluster" {
    source = "${path.module}/../../modules/ceph-cluster"

    namespace     = "rook-ceph"
    cluster_name  = "base"
    device_filter = "^vd[b-c]$"
}

# Creates a Ceph object storage bucket.
# This module uses the 'ceph-bucket' module to create an S3-compatible
# bucket within the deployed Ceph cluster.
module "ceph_bucket" {
    source = "${path.module}/../../modules/ceph-bucket"

    namespace          = "rook-ceph"
    storage_class_name = module.ceph_cluster.storage_class_name
    bucket_name        = "warehouse"
    
    depends_on = [module.ceph_cluster]
}
