variable "namespace" {
  type        = string
  description = "Kubernetes namespace to install the ClickHouse operator to."
}

variable "release_name" {
  description = "The name of the Helm release for the ClickHouse operator."
  type        = string
  default     = "clickhouse-operator"
}

variable "chart_repository" {
  description = "The URL of the Helm chart repository for the ClickHouse operator."
  type        = string
  default     = "https://docs.altinity.com/clickhouse-operator"
}

variable "chart_name" {
  description = "The name of the Helm chart for the ClickHouse operator."
  type        = string
  default     = "altinity-clickhouse-operator"
}

variable "chart_version" {
  description = "The version of the Helm chart for the ClickHouse operator."
  type        = string
  default     = "0.25.6"
}
