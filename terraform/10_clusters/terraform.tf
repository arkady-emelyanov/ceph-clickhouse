terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
    }
    helm = {
      source  = "hashicorp/helm"
    }
    kubectl = {
      source  = "gavinbunney/kubectl"
    }
  }

  backend "local" {
    path = "terraform.tfstate"
  }
}

provider "kubernetes" {
  config_path = var.kubeconfig_path
  config_context = "minikube"
}

provider "helm" {
  kubernetes = {
    config_path = var.kubeconfig_path
    config_context = "minikube"
  }
}

provider "kubectl" {
  config_path = var.kubeconfig_path
  config_context = "minikube"
}
