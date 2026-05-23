variable "clustername_dependency" {
  description = "The name of the EKS cluster"
  type        = string
}

variable "alb_controller_irsa_arn" {
  description = "The IAM role for the AWS Load Balancer Controller"
  type        = string
}