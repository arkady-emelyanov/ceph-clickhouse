output "storage_class_name" {
  value       = local.storage_class_name
  sensitive   = false
  description = "The name of the storage class for Object Store"
}
