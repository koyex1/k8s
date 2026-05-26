variable "alb_controller_irsa_arn" {
  description = "The ARN of the IAM role for the AWS Load Balancer Controller"
  type        = string
}

variable "cluster_name" {
  description = "The name of the EKS cluster"
  type        = string
}

variable "region" {
  description = "The AWS region where the EKS cluster is deployed"
  type        = string
}

variable "vpc_id" {
  description = "The ID of the VPC where the EKS cluster is deployed"
  type        = string
}

variable "alb_dependency" {
  description = "Loadbalancer depends on loadbalancer IRSA being created"
  type        = any
}
