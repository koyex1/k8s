output "eks_cluster_role_arn" {
  value = module.eks_cluster_role.iam_role_arn
}

output "nodegroup_role_arn" {
  value = module.eks_nodegroup_role.iam_role_arn
}

output "alb_role_arn" {
  value = module.alb_irsa.iam_role_arn
}

output "bastion_instance_profile" {
  value = aws_iam_instance_profile.bastion_profile.name
}