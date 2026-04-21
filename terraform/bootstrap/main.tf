module "s3_bucket" {
    source = "./modules/aws-s3bucket"
    bucket_name = var.bucket_name
}

module "dynamodb_table" {
    source = "./modules/aws-dynamodb"
    dynamodb_table = var.dynamodb_table
}