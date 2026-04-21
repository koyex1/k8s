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

  allowed_ssh_cidr = ["0.0.0.0/0"] # my ip ["YOUR-IP/32"] lock this down
}

module "eks" {
  source = "../../modules/aws-eks"

  cluster_name    = env.cluster_name
  cluster_version = "1.29"
  env             = var.env

  vpc_id             = module.vpc.vpc_id
  private_subnet_ids = module.vpc.private_subnets

  security_group_ids = [module.security.eks_cluster_sg_id]

  eks_cluster_role_arn = module.iam.eks_cluster_role_arn
  eks_node_role_arn    = module.iam.nodegroup_role_arn

  instance_types = ["t3.medium"]

  min_capacity_on_demand     = 1
  max_capacity_on_demand     = 2
  desired_capacity_on_demand = 1
}

#IAM
module "iam" {
  source = "../../modules/aws-iam"

  cluster_name      = var.cluster_name
  oidc_provider_arn = module.eks.oidc_provider_arn
  oidc_provider_url = module.eks.oidc_provider
}

module "bastion" {
  source = "../../modules/aws-bastion"

  image_id      = "ami-0ec10929233384c7f"
  instance_type = "t3.micro"

  subnet_id       = module.vpc.public_subnets[0]
  security_groups = [module.security.bastion_sg_id]

  iam_instance_profile_name = module.iam.bastion_instance_profile

  associate_public_ip = true
  enable_eip          = true

  key_name = "devopspemkey" # get a keypair 

  user_data = file("${path.module}/user-data.sh")

  tags = {
    Environment = "dev"
  }
}

module "atlantis" {
  source = "../../modules/helm-atlantis"

  region = var.region

  repo_allowlist = "github.com/koyex1/*"

  github_user           = "your-github-username"
  github_token          = "your-github-token"
  github_webhook_secret = "your-webhook-secret"

  atlantis_url = "http://your-atlantis-url"

  alb_dependency = helm_release.aws-load-balancer-controller
}
