resource "aws_dynamodb_table" "tf_lock" {
name = var.dynamodb_table
billing_mode = "PAY_PER_REQUEST"
hash_key = "LockID" #hash key here is the primary key of the table. you can name it as you like but it should be same as the attribute name below.
attribute { #attribute here is the primary key of the table.
  name = "LockID"
  type = "S"
}
}