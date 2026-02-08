variable "bucket_name" {
  type = string
  description = "The name of the bucket to create"
}

variable "namespace" {
    type = string
    default = "rook-ceph"
    description = "Namespace to deploy cluster to"
}

variable "storage_class_name" {
  type = string
  description = "The name of the cluster"
}
