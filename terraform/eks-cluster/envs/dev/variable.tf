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

variable "terraform_version" {
  description = "The version of Terraform to use"
  type        = string
}

variable "git_user" {
  description = "GitHub username for Atlantis"
  type        = string
}

variable "git_access_token" {
  description = "GitHub access token for Atlantis"
  type        = string
}

variable "webhook_secret" {
  description = "Webhook secret for Atlantis"
  type        = string
}

variable "aws_access_key_id" {
  description = "AWS Access Key ID for Atlantis"
  type        = string
}

variable "aws_secret_access_key" {
  description = "AWS Secret Access Key for Atlantis"
  type        = string
}

variable "aws_region" {
  description = "AWS region for Atlantis"
  type        = string
}

variable "vault_root_token" {
  description = "Root token for Vault development server"
  type        = string
}