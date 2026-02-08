variable "cluster_name" {
  type        = string
  default     = "ceph"
  description = "The name of the Ceph cluster."
}

variable "namespace" {
  type        = string
  default     = "rook-ceph"
  description = "The Kubernetes namespace where the Ceph cluster will be deployed."
}

variable "device_filter" {
  type        = string
  description = "A filter to select which block devices to use for the Ceph cluster. For example, `^sd[a-z]` to use all `sd` devices."
}
