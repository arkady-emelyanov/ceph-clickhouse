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

variable "shards_count" {
  type        = number
  default     = 3
  description = "The number of shards to provision"
}

variable "replicas_count" {
  type        = number
  default     = 1
  description = "The number of replicas to provision"
}

variable "disk_size" {
  type        = string
  default     = "10Gi"
  description = "Disk size to provision for each node"
}
