module "vpc" {
  source = "../../modules/aws-vpc"
  env          = var.env
  cluster_name = var.cluster_name

  vpc_cidr_block = "10.0.0.0/16"

  public_subnet = [
    "10.0.1.0/24",
    "10.0.2.0/24",
    "10.0.3.0/24"
  ]

  private_subnet = [
    "10.0.4.0/24",
    "10.0.5.0/24",
    "10.0.6.0/24"
  ]
}

module "security" {
  source = "../../modules/aws-security-group"

  vpc_id = module.vpc.vpc_id

  env = var.env

  allowed_ssh_cidr = ["0.0.0.0/0"] # my ip ["YOUR-IP/32"] lock this down
}

module "eks" {
  source = "../../modules/aws-eks"

  cluster_name    = var.cluster_name
  cluster_version = "1.34" #1.36
  env             = var.env

  vpc_id             = module.vpc.vpc_id
  private_subnet_ids = module.vpc.private_subnets

  security_group_ids = [module.security.eks_cluster_sg_id]

  eks_cluster_role_arn = module.iam.eks_cluster_role_arn
  eks_node_role_arn    = module.iam.nodegroup_role_arn

  instance_types = ["c7i-flex.large"] # has a vcpu of 2 and a RAM of 4GB.

  min_capacity_on_demand     = 1
  max_capacity_on_demand     = 2
  desired_capacity_on_demand = 1
}

#IAM
module "iam" {
  source = "../../modules/aws-iam"

  cluster_name      = var.cluster_name
  oidc_provider_arn = module.eks.oidc_provider_arn
  oidc_provider_url = startswith(module.eks.oidc_provider, "https://") ? module.eks.oidc_provider : "https://${module.eks.oidc_provider}"
}

module "bastion" {
  source = "../../modules/aws-bastion"

  env = var.env

  image_id      = "ami-0ec10929233384c7f"
  instance_type = "t3.micro"

  subnet_id       = module.vpc.public_subnets[0]
  security_groups = [module.security.bastion_sg_id]

  iam_instance_profile_name = module.iam.bastion_instance_profile

  associate_public_ip = true
  enable_eip          = true

  key_name = "devopspemkey" # get a keypair 

  user_data = file("../../modules/aws-bastion/user-data.sh")

  tags = {
    Environment = "dev"
  }
}

module "alb-controller" {
  source = "../../modules/helm-alb-controller"

  cluster_name            = var.cluster_name
  region                  = var.region
  vpc_id                  = module.vpc.vpc_id
  alb_controller_irsa_arn = module.iam.alb_role_arn
  alb_dependency = [module.alb_controller_service_account, module.iam.alb_role_arn]
}

module "argocd" {
  source = "../../modules/helm-argocd"

  argo_dependency = [ module.alb-controller ]
}

module "atlantis" {
  source = "../../modules/helm-atlantis"

  region = var.region

  repo_allowlist = "github.com/koyex1/*"

  #github credentials for atlantis to access the repo and manage PRs. Make sure to store these securely and not hardcode in production.

  terraform_version = "1.14.8"

  atlantis_url = "http://your-atlantis-url" 

  alb_dependency = module.alb-controller
}

module karpenter {
  source = "../../modules/helm-karpenter"

  cluster_name            = var.cluster_name
  cluster_endpoint        = module.eks.cluster_endpoint
  karpenter_role_arn      = module.iam.karpenter_role_arn
  karpenter_instance_profile = module.iam.karpenter_instance_profile

  karpenter_dependency = [module.eks, module.iam]
}


module "prometheus" {
  source = "../../modules/helm-prometheus"
}

module "alb_controller_service_account" {
  source = "../../modules/kubernetes-serviceAccount"

  clustername_dependency  = var.cluster_name
  alb_controller_irsa_arn = module.iam.alb_role_arn
}


