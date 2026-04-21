#BUCKET CREATION
resource "aws_s3_bucket" "tf_state" {
    bucket = var.bucket_name
    force_destroy = true

    tags = {
        Namme = "terraform-state"
    }
}

#VERSIONING 
resource "aws_s3_bucket_versioning" "versioning" {
    bucket = aws_s3_bucket.tf_state.id
    versioning_configuration {
        status = "Enabled"
    }
}

#ENCRYPTION
resource "aws_s3_bucket_server_side_encryption_configuration" "encryption" {
    bucket = aws_s3_bucket.tf_state.id
    rule {
        apply_server_side_encryption_by_default {
            sse_algorithm = "AES256"
        }
    }
}

