provider "kubernetes" {
  host                   = data.terraform_remote_state.current_state.outputs.cluster_endpoint
  cluster_ca_certificate = base64decode(data.terraform_remote_state.current_state.outputs.cluster_ca)
  token                  = data.terraform_remote_state.current_state.outputs.eks_cluster_token
  exec {
    api_version = "client.authentication.k8s.io/v1"
    command = "aws"
    args    = ["eks", "get-token", "--cluster-name", data.terraform_remote_state.current_state.outputs.cluster_name]
  }
}

provider "helm" {
  kubernetes = {
    host                   = data.terraform_remote_state.current_state.outputs.cluster_endpoint
    cluster_ca_certificate = base64decode(data.terraform_remote_state.current_state.outputs.cluster_ca)
    token                  = sensitive(data.terraform_remote_state.current_state.outputs.eks_cluster_token)
    exec = {
      api_version = "client.authentication.k8s.io/v1"
      command     = "aws"
      args        = ["eks", "get-token", "--cluster-name", data.terraform_remote_state.current_state.outputs.cluster_name]

    }
  }
}