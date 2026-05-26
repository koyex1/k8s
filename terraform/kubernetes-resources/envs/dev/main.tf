locals {
  aws-tf-state = local.aws-tf-state
}

module "alb-controller" {
  source = "../../modules/helm-alb-controller"

  cluster_name            = local.aws-tf-state.cluster_name
  region                  = local.aws-tf-state.region
  vpc_id                  = local.aws-tf-state.vpc_id
  alb_controller_irsa_arn = local.aws-tf-state.alb_controller_irsa_arn
  alb_dependency = [module.alb_controller_service_account, local.aws-tf-state.alb_controller_irsa_arn]
}

module "argocd" {
  source = "../../modules/helm-argocd"

  argo_dependency = [ module.alb-controller ]
}

module "atlantis" {
  source = "../../modules/helm-atlantis"

  region = local.aws-tf-state.region

  repo_allowlist = "github.com/koyex1/*"

  #github credentials for atlantis to access the repo and manage PRs. Make sure to store these securely and not hardcode in production.
  github_user           
  
  terraform_version = "1.14.8"

  atlantis_url = "http://your-atlantis-url" 

  alb_dependency = module.alb-controller
}

module karpenter {
  source = "../../modules/helm-karpenter"

  cluster_name            = local.aws-tf-state.cluster_name
  cluster_endpoint        = local.aws-tf-state.cluster_endpoint
  karpenter_role_arn      = local.aws-tf-state.karpenter_role_arn
  karpenter_instance_profile = local.aws-tf-state.karpenter_instance_profile

  karpenter_dependency = [module.eks, module.iam]
}


module "prometheus" {
  source = "../../modules/helm-prometheus"
}

module "alb_controller_service_account" {
  source = "../../modules/kubernetes-serviceAccount"

  clustername_dependency  = local.aws-tf-state.cluster_name
  alb_controller_irsa_arn = local.aws-tf-state.alb_controller_irsa_arn
}


