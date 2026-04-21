variable "region" {
  description = "The AWS region where the S3 bucket and DynamoDB table will be created"
  type        = string
}

variable "env" {
  description = "The environment name (e.g., dev, staging, prod)"
  type        = string
}

variable "cluster_name" {
  description = "The name of the EKS cluster"
  type        = string
}
