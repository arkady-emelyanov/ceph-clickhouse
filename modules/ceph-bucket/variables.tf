variable "bucket_name" {
  type        = string
  description = "The name of the Ceph object storage bucket to create."
}

variable "namespace" {
  type        = string
  default     = "rook-ceph"
  description = "The Kubernetes namespace where the Ceph object storage bucket will be created."
}

variable "storage_class_name" {
  type        = string
  description = "The name of the StorageClass used for the Ceph object storage bucket."
}
