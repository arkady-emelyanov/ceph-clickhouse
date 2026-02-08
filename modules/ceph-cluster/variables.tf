variable "cluster_name" {
  type = string
  default = "ceph"
  description = "The name of the cluster"
}

variable "namespace" {
  type = string
  default = "rook-ceph"
  description = "Namespace to deploy cluster to"
}

variable "device_filter" {
  type = string
  default = "^vd[b-c]$"
  description = "Block device filter"
}
