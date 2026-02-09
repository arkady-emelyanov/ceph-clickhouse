locals {
  # https://github.com/Altinity/helm-charts/tree/main/charts/clickhouse
  clickhouse_cluster_values = {    
    operator = {
      # operator is installed separately, do not install embedded operator.
      enabled = false
    }

    clickhouse = {
      shardsCount = var.shards_count
      replicasCount = var.replicas_count

      persistence = {
        size = var.disk_size
      }
    }

    keeper = {
      enabled = true
    }
  }
}

# This resource deploys a ClickHouse cluster using the Altinity Helm chart.
# It configures the number of shards, replicas, persistence, and enables the ClickHouse Keeper.
resource "helm_release" "clickhouse_cluster" {
  name       = var.cluster_name
  repository = var.chart_repository
  chart      = var.chart_name
  version    = var.chart_version

  namespace  = var.namespace
  create_namespace = false

  values = [jsonencode(local.clickhouse_cluster_values)]  
  wait = true
}
