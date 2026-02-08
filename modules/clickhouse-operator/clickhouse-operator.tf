locals {
  # https://github.com/Altinity/helm-charts/tree/main/charts/clickhouse
  clickhouse_operator_values = {}
}

# This resource deploys the Altinity ClickHouse operator using the official Helm chart.
# The operator is responsible for managing ClickHouse clusters in Kubernetes.
resource "helm_release" "clickhouse_operator" {
  name       = var.release_name
  repository = var.chart_repository
  chart      = var.chart_name
  version    = var.chart_version

  namespace  = var.namespace
  create_namespace = false

  values = [jsonencode(local.clickhouse_operator_values)]  
  wait = true
}
