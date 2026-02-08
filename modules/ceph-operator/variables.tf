variable "namespace" {
  type        = string
  description = "Kubernetes namespace to install the to"
}

variable "release_name" {
  description = "Helm release name"
  type        = string
  default     = "rook-ceph"
}

variable "chart_repository" {
  description = "Helm chart repository URL (release channel)"
  type        = string
  default     = "https://charts.rook.io/release"
}

variable "chart_name" {
  description = "Chart name"
  type        = string
  default     = "rook-ceph"
}

variable "chart_version" {
  description = "Chart version"
  type        = string
  default     = "v1.19.0"
}
