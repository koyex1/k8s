output "eks_cluster_role_arn" {
  value = module.eks_cluster_role.arn
}

output "nodegroup_role_arn" {
  value = module.eks_nodegroup_role.arn
}

output "alb_role_arn" {
  value = module.alb_irsa.arn
}

output "ebs_csi_role_arn" {
  value = module.ebs_csi_irsa.arn
}

output "bastion_instance_profile" {
  value = aws_iam_instance_profile.bastion_profile.name
}

output "karpenter_role_arn" {
  value = module.karpenter_irsa.arn
}

output "karpenter_instance_profile" {
  value = aws_iam_instance_profile.karpenter.name
}
