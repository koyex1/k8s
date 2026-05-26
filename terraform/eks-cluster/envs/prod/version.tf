terraform {
  required_version = "value"

  backend "s3" {
    bucket         = "eks-terraform-state"
    dynamodb_table = "terraform-locks"
    key            = "security/prod/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "6.41.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "3.1.1"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "3.1.0"
    }
  }
  
}