locals {
  # see: https://github.com/rook/rook/blob/master/deploy/charts/rook-ceph/values.yaml
  rook_values = {
    operatorNamespace = var.namespace
    operatorLogLevel = "INFO"

    csi = {
      enableRbdDriver = false
      enableCephfsDriver = false
    }
  }
}

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
