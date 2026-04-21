resource "helm_release" "aws-load-balancer-controller" {
  name       = "aws-load-balancer-controller"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  version    = "1.17.0"
  # timeout         = 2000
  namespace       = "kube-system"
  cleanup_on_fail = true
  recreate_pods   = true
  replace         = true
  force_update    = true

  set {
    name  = "clusterName"
    value = var.cluster_name
  }

  set {
    name  = "region"
    value = var.region
  }

  set {
    name  = "vpcId"
    value = var.vpc_id
  }

  set {
    name  = "serviceAccount.create"
    value = "false" #already created in kuberentes_service_account.alb_controller_sa to handle this. to avoid duplication.
  }

  set {
    name  = "serviceAccount.name"
    value = "aws-load-balancer-controller"
  }

  set {
    name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = module.iam.alb_irsa.iam_role_arn
  }

  values = [
    yamlencode({
      enableGatewayAPI = true
      extraArgs = {
        "enable-gateway-api" = "true"
      }
    })
  ]

  depends_on = [kubernetes_service_account.alb_controller_sa, module.iam.alb_irsa]
}