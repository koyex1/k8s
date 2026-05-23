resource "helm_release" "aws-load-balancer-controller" {
  name       = "aws-load-balancer-controller"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  version    = "1.17.0"
  #timeout         = 2000
  namespace       = "kube-system"
  cleanup_on_fail = true
  recreate_pods   = true
  replace         = true
  force_update    = true

  set = [{
    name  = "clusterName"
    value = var.cluster_name
    },
    {
      name  = "region"
      value = var.region
    },
    {
      name  = "vpcId"
      value = var.vpc_id
    },
    {
      name  = "serviceAccount.create"
      value = "false" #already created in kuberentes_service_account.alb_controller_sa to handle this. to avoid duplication.
    },
    {
      name  = "serviceAccount.name"
      value = "aws-load-balancer-controller"
    },
    {
      name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
      value = var.alb_controller_irsa_arn
    }
  ]

  values = [
    yamlencode({
      enableGatewayAPI = true
      extraArgs = {
        "enable-gateway-api" = "true"
      }
    })
  ]

  depends_on = [var.alb_dependency] #kubernetes_service_account.alb_controller_sa, 
}
