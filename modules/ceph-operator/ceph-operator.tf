locals {
  # see: https://rook.io/docs/rook/latest-release/Getting-Started/quickstart/#deploy-the-rook-operator
  rook_values = {
    operatorNamespace = var.namespace
    operatorLogLevel = "INFO"

    csi = {
      enableRbdDriver = false
      enableCephfsDriver = false
    }
  }
}

# This resource deploys the Rook Ceph operator using the official Helm chart.
# The operator is responsible for managing Ceph clusters in Kubernetes.
resource "helm_release" "rook_operator" {
  name       = var.release_name
  repository = var.chart_repository
  chart      = var.chart_name
  version    = var.chart_version

  namespace  = var.namespace
  create_namespace = false

  values = [jsonencode(local.rook_values)]  
  wait = true
}
