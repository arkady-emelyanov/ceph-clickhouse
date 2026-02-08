variable "namespace" {
  type        = string
  description = "Kubernetes namespace to install the Ceph operator to."
}

variable "release_name" {
  description = "The name of the Helm release for the Ceph operator."
  type        = string
  default     = "rook-ceph"
}

variable "chart_repository" {
  description = "The URL of the Helm chart repository for the Ceph operator."
  type        = string
  default     = "https://charts.rook.io/release"
}

variable "chart_name" {
  description = "The name of the Helm chart for the Ceph operator."
  type        = string
  default     = "rook-ceph"
}

variable "chart_version" {
  description = "The version of the Helm chart for the Ceph operator."
  type        = string
  default     = "v1.19.0"
}
