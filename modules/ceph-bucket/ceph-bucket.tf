# This resource creates a Ceph object storage bucket.
# The bucket.yaml file is a template that defines the CephBucketClaim custom resource.
resource "kubectl_manifest" "bucket" {
  yaml_body = templatefile("${path.module}/bucket.yaml", {
    bucket_name        = var.bucket_name
    bucket_namespace   = var.namespace
    storage_class_name = var.storage_class_name
  })
}
