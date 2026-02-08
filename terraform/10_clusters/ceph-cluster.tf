module "ceph_cluster" {
    source = "${path.module}/../../modules/ceph-cluster"

    namespace     = "rook-ceph"
    cluster_name  = "base"
    device_filter = "^vd[b-c]$"
}

module "ceph_bucket" {
    source = "${path.module}/../../modules/ceph-bucket"

    namespace          = "rook-ceph"
    storage_class_name = module.ceph_cluster.storage_class_name
    bucket_name        = "warehouse"
    
    depends_on = [module.ceph_cluster]
}
