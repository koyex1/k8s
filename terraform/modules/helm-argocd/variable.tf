variable "argo_dependency" {
  description = "A list of resources that the ArgoCD Helm release depends on"
  type        = list(any)
}