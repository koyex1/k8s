variable "cluster_name" {
  description = "The name of the EKS cluster"
  type        = string
}

variable "cluster_endpoint" {
  description = "The endpoint of the EKS cluster"
  type        = string
}

variable "karpenter_role_arn" {
  description = "The ARN of the IAM role for Karpenter"
  type        = string
}

variable "karpenter_instance_profile" {
  description = "The name of the instance profile for Karpenter"
  type        = string
}

variable "karpenter_dependency" {
  description = "A list of resources that the Karpenter Helm release depends on"
  type        = list(any)
}