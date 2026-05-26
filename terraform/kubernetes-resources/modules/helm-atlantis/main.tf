resource "helm_release" "atlantis" {
  name       = "atlantis"
  repository = "https://runatlantis.github.io/helm-charts"
  chart      = "atlantis"
  version    = "6.2.0"

  namespace        = "atlantis"
  create_namespace = true

  cleanup_on_fail = true
  recreate_pods   = true
  replace         = true

  # CORE CONFIG
  set = [
    {
      name  = "orgAllowlist"
      value = var.repo_allowlist
    },
    {
      name  = "environment.AWS_DEFAULT_REGION"
      value = var.region
    },
    { # SERVICE (EXPOSE VIA ALB)
      # AWS Load Balancer Controller — a pod running inside your Kubernetes cluster that watches for Service or Ingress resources and creates AWS load balancers in response
      name  = "service.type"
      value = "LoadBalancer"
    },
    {
      name  = "service.annotations.service\\.beta\\.kubernetes\\.io/aws-load-balancer-scheme"
      value = "internet-facing"
    },
    { # TERRAFORM VERSION
      name  = "terraformVersion"
      value = var.terraform_version
    }
  ]

  # GITHUB CONFIG
  set_sensitive = [
    {
      name  = "github.user"
      value = var.github_user
    },
    {
      name  = "github.token"
      value = var.github_token
    },
    {
      name  = "github.secret"
      value = var.github_webhook_secret
    }
  ]

  # ENABLE WORKFLOWS
  values = [
    yamlencode({
      atlantisUrl = var.atlantis_url

      repoConfig = yamlencode({
        repos = [
          {
            id                 = "/.*/"
            apply_requirements = ["approved"]
            workflow           = "default"
          }
        ]
      })
    })
  ]

  depends_on = [
    var.alb_dependency
  ]
}


## ------------- recommendations -----------
# setup - github token -> github webhook & webhook secret
# instead of loadbalancer. use ingress 
