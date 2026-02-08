resource "kubectl_manifest" "bucket" {
  yaml_body = templatefile("${path.module}/bucket.yaml", {
    bucket_name = var.bucket_name
    bucket_namespace = var.namespace
    storage_class_name = var.storage_class_name
  })
}
