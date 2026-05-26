terraform {
  required_version = "1.14.8"

  backend "s3" {
    bucket         = "eks-olu-tf-state-bucket"
    dynamodb_table = "eks-olu-tf-lock-table"
    key            = "security/eks-cluster/dev/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}
