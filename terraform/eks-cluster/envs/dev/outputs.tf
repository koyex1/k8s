output "ami_id_amazon_filtered" {
    value = data.aws_ami.amazon_linux.id
}

output "ami_id_ubuntu_filtered" {
    value = data.aws_ami.ubuntu.id
}

output "cluster_name" {
    value = module.eks.cluster_name
}

output "vpc_id" {
    value = var.cluster_name
}

output "region" {
    value = var.region
}

output "alb_controller_irsa_arn" {
    value = module.iam.alb_role_arn
}

output "karpenter_instance_profile" {
    value = module.iam.karpenter_instance_profile
}

output "karpenter_role_arn" {
    value = module.iam.karpenter_role_arn
}

