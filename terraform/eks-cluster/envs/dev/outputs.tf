output "ami_id_amazon_filtered" {
    value = data.aws_ami.amazon_linux.id
}

output "ami_id_ubuntu_filtered" {
    value = data.aws_ami.ubuntu.id
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

output "eks" {
    value = module.eks
    sensitive = true
}

output "cluster_name" {
    value = module.eks.cluster_name
}

output "cluster_endpoint" {
    value = module.eks.cluster_endpoint
}

output "cluster_ca" {
    value = module.eks.cluster_ca
    sensitive = true
}

output "eks_cluster_token" {
    value = data.aws_eks_cluster_auth.cluster.token
    sensitive = true
}

output "bastion_public_ip" {
    value = module.bastion.bastion_public_ip
}

output "bastion_console_output" {
    value = module.bastion.bastion_console_output
}

