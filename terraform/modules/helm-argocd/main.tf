resource "helm_release" "argocd" {
  name             = "argocd"
  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argo-cd"
  version          = "9.5.3"
  namespace        = "argocd"
  create_namespace = true
  #   timeout          = 2000
  cleanup_on_fail = true
  recreate_pods   = true
  replace         = true

  # AWS Load Balancer Controller — a pod running inside your Kubernetes cluster that watches for Service or Ingress resources and creates AWS load balancers in response
  # change this from loadbalancer to clusterip and then create an ingress resource with the correct annotations to use the AWS load balancer controller to create the load balancer for you.
  #just need to make sure that the service type is clusterip and then create an ingress resource with the correct annotations to use the AWS load balancer controller to create the load balancer for you.
  set = [
    {
      name  = "server.service.type"
      value = "LoadBalancer" #LoadBalancer #ClusterIP #NodePort
    },
    {
      name  = "server.ingress.enabled"
      value = "false"
    },
    {
      name  = "server.extraArgs[0]"
      value = "--insecure" #--insecure or secure
    },
    {
      name  = "server.service.annotations.service\\.beta\\.kubernetes\\.io/aws-load-balancer-internal"
      value = "false"
    },
    {
      name  = "crds.keep"
      value = "false"
    }
  ]

  depends_on = [var.argo_dependency]
}

data "kubernetes_service_v1" "argocd_server" {
  metadata {
    name      = "argocd-server"
    namespace = "argocd"
  }
  depends_on = [var.argo_dependency]
}

#----------------recommendation----------------
#insecure to secure.
#ClusterIP and expose via ingress
