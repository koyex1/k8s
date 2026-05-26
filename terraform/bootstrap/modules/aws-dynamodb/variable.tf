variable "dynamodb_table" {
    description = "The name of the DynamoDB table to create for Terraform state locking"
    type        = string
}