# Deploys a ClickHouse cluster.
# This module uses the 'clickhouse-cluster' module to provision a ClickHouse cluster
# with a specific name and namespace.
module "clickhouse_cluster" {
    source = "${path.module}/../../modules/clickhouse-cluster"

    namespace = "clickhouse-system"
    cluster_name = "clickhouse"

    disk_size = "500Gi"
    shards_count = 3
    replicas_count = 1
}
