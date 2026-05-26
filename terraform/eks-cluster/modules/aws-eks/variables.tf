variable "cluster_name" {}
variable "cluster_version" {}
variable "env" {}

variable "vpc_id" {}
variable "private_subnet_ids" {}

# variable "cluster_security_group_id" {
#   type = string
# }

variable "eks_cluster_role_arn" {}
variable "eks_node_role_arn" {}
variable "ebs_csi_role_arn" {}

variable "instance_types" {
  type = list(string)
}

variable "desired_capacity_on_demand" {}
variable "min_capacity_on_demand" {}
variable "max_capacity_on_demand" {}
variable "key_name" {
  default = null
}

