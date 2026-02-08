# This section deploys the Rook Ceph operator into the Kubernetes cluster.
# The Rook Ceph operator manages the lifecycle of Ceph clusters on Kubernetes.
resource "kubernetes_namespace_v1" "rook" {
  metadata {
    name = "rook-ceph"
  }
}

module "rook_operator" {
  source    = "${path.module}/../../modules/ceph-operator"
  namespace = kubernetes_namespace_v1.rook.metadata[0].name
}


# This section deploys the Altinity ClickHouse operator into the Kubernetes cluster.
# The ClickHouse operator manages the lifecycle of ClickHouse clusters on Kubernetes.
resource "kubernetes_namespace_v1" "clickhouse" {
  metadata {
    name = "clickhouse-system"
  }
}

module "clickhouse_operator" {
  source    = "${path.module}/../../modules/clickhouse-operator"
  namespace = kubernetes_namespace_v1.clickhouse.metadata[0].name
}
