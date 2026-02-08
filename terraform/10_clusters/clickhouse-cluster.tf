module "clickhouse_cluster" {
    source = "${path.module}/../../modules/clickhouse-cluster"

    namespace = "clickhouse-system"
    cluster_name = "clickhouse"
}
