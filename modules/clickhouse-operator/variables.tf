variable "namespace" {
  type        = string
  description = "Kubernetes namespace to install the to"
}

variable "release_name" {
  description = "Helm release name"
  type        = string
  default     = "clickhouse-operator"
}

variable "chart_repository" {
  description = "Helm chart repository URL (release channel)"
  type        = string
  default     = "https://docs.altinity.com/clickhouse-operator"
}

variable "chart_name" {
  description = "Chart name"
  type        = string
  default     = "altinity-clickhouse-operator"
}

variable "chart_version" {
  description = "Chart version"
  type        = string
  default     = "0.25.6"
}
