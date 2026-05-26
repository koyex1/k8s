resource "helm_release" "karpenter" {
  name       = "karpenter"
  repository = "https://charts.karpenter.sh"
  chart      = "karpenter"
  version    = "0.16.3"

  namespace        = "karpenter"
  create_namespace = true

  set = [
    {
      name  = "settings.clusterName"
      value = var.cluster_name
    },
    {
      name  = "settings.clusterEndpoint"
      value = var.cluster_endpoint
    },
    {
      name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
      value = var.karpenter_role_arn
    },
    {
      name  = "settings.defaultInstanceProfile"
      value = var.karpenter_instance_profile
    }
  ]

  depends_on = [var.karpenter_dependency]
}
