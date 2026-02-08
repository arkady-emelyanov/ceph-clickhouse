variable "namespace" {
  type        = string
  description = "The Kubernetes namespace where the ClickHouse cluster will be deployed."
}

variable "cluster_name" {
  description = "The name of the ClickHouse cluster."
  type        = string
}

variable "chart_repository" {
  description = "The URL of the Helm chart repository for the ClickHouse cluster."
  type        = string
  default     = "https://helm.altinity.com/"
}

variable "chart_name" {
  description = "The name of the Helm chart for the ClickHouse cluster."
  type        = string
  default     = "clickhouse"
}

variable "chart_version" {
  description = "The version of the Helm chart for the ClickHouse cluster."
  type        = string
  default     = "0.3.8"
}
