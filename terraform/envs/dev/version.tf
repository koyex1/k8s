terraform {
  required_version = "1.14.8"

  backend "s3" {
    bucket         = "eks-olu-tf-state-bucket"
    dynamodb_table = "eks-terraform-lock-table"
    key            = "security/dev/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
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
