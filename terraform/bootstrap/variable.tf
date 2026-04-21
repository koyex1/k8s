variable "region" {
  description = "The AWS region where the S3 bucket and DynamoDB table will be created"
  type        = string
}

variable "bucket_name" {
  description = "The name of the S3 bucket to create"
  type        = string
}

variable "dynamodb_table" {
    description = "The name of the DynamoDB table to create for Terraform state locking"
    type        = string
}

