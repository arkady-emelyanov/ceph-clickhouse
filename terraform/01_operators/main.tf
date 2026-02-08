# Rook/Ceph
resource "kubernetes_namespace_v1" "rook" {
  metadata {
    name = "rook-ceph"
  }
}

module "rook_operator" {
  source = "${path.module}/../../modules/ceph-operator"
  namespace = kubernetes_namespace_v1.rook.metadata[0].name
}


# ClickHouse
resource "kubernetes_namespace_v1" "clickhouse" {
  metadata {
    name = "clickhouse-system"
  }
}

module "clickhouse_operator" {
  source = "${path.module}/../../modules/clickhouse-operator"
  namespace = kubernetes_namespace_v1.clickhouse.metadata[0].name
}
