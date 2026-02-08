variable "namespace" {
  type = string
  description = "Namespace to deploy cluster to"
}

variable "cluster_name" {
  description = "Helm release name"
  type        = string
}

variable "chart_repository" {
  description = "Helm chart repository URL (release channel)"
  type        = string
  default     = "https://helm.altinity.com/"
}

variable "chart_name" {
  description = "Chart name"
  type        = string
  default     = "clickhouse"
}

variable "chart_version" {
  description = "Chart version"
  type        = string
  default     = ""
}
