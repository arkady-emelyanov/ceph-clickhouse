variable "kubeconfig_path" {
  description = "Path to kubeconfig file used to access your Minikube cluster"
  type        = string
  default     = "~/.kube/config"
}
