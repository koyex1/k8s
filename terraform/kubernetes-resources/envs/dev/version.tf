terraform {
  required_version = "1.14.8"

  backend "s3" {
    bucket         = "eks-olu-tf-state-bucket"
    dynamodb_table = "eks-olu-tf-lock-table"
    key            = "security/kubernetes-resources/dev/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
  }

  required_providers {
      helm = {
      source  = "hashicorp/helm"
      version = "~> 3.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 3.0"
    }
  }
}