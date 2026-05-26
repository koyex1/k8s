variable "env" {}
variable "cluster_name" {}

variable "vpc_cidr_block" {
  default = "10.0.0.0/16"
}

variable "public_subnet" {
  type = list(string)
}

variable "private_subnet" {
  type = list(string)
}