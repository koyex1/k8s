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