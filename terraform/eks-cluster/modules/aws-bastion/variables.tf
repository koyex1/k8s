variable "image_id" {}
variable "instance_type" {}
variable "subnet_id" {}

variable "security_groups" {
  type = list(string)
}

variable "iam_instance_profile_name" {}

variable "key_name" {
  default = null
}

variable "associate_public_ip" {
  default = false
}

variable "enable_eip" {
  default = false
}

variable "tags" {
  type = map(string)
}

variable "user_data" {}

variable "env" {}