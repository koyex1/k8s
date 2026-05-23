resource "helm_release" "prometheus-helm" {
  name             = "prometheus"
  repository       = "https://prometheus-community.github.io/helm-charts"
  chart            = "kube-prometheus-stack"
  version          = "83.7.0"
  namespace        = "prometheus"
  create_namespace = true
  cleanup_on_fail  = true
  recreate_pods    = true
  replace          = true

  timeout = 2000

  set = [
    {
      name  = "podSecurityPolicy.enabled"
      value = true
    },
    {
      name  = "server.persistentVolume.enabled"
      value = true
    },
    {
      name  = "grafana.service.type"
      value = "LoadBalancer"
    },
    {
      name  = "grafana.service.annotations.service\\.beta\\.kubernetes\\.io/aws-load-balancer-scheme"
      value = "internet-facing"
    },
    { # AWS Load Balancer Controller — a pod running inside your Kubernetes cluster that watches for Service or Ingress resources and creates AWS load balancers in response
      name  = "prometheus.service.type"
      value = "LoadBalancer"
    },
    {
      name  = "prometheus.service.annotations.service\\.beta\\.kubernetes\\.io/aws-load-balancer-scheme"
      value = "internet-facing"
    }
  ]

  values = [
    yamlencode({
      prometheus = {
        prometheusSpec = {
          resources = {
            requests = {
              cpu    = "500m"
              memory = "1Gi"
            }
          }
        }
      }
    })
  ]
}

data "kubernetes_service_v1" "prometheus_server" {
  metadata {
    name      = "prometheus-kube-prometheus-prometheus"
    namespace = "prometheus"
  }
  depends_on = [helm_release.prometheus-helm]
}

data "kubernetes_service_v1" "grafana_server" {
  metadata {
    name      = "prometheus-grafana"
    namespace = "prometheus"
  }
  depends_on = [helm_release.prometheus-helm]
}


#----------------recommendation----------------
#ClusterIP and expose via ingress
# set {
#  name  = "prometheus.prometheusSpec.storageSpec.volumeClaimTemplate.spec.resources.requests.storage"
#  value = "20Gi"
#}
