variable "cluster_name" {}
variable "cluster_version" {}
variable "env" {}

variable "vpc_id" {}
variable "private_subnet_ids" {}

variable "security_group_ids" {
  type = list(string)
}

variable "eks_cluster_role_arn" {}
variable "eks_node_role_arn" {}

variable "instance_types" {
  type = list(string)
}

variable "desired_capacity_on_demand" {}
variable "min_capacity_on_demand" {}
variable "max_capacity_on_demand" {}
