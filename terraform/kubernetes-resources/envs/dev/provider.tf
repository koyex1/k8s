provider "kubernetes" {
  host                   = data.terraform_remote_state.network.outputs.cluster_endpoint
  cluster_ca_certificate = base64decode(data.terraform_remote_state.network.outputs.cluster_ca)
  token                  = data.aws_eks_cluster_auth.cluster.token
  exec {
    api_version = "client.authentication.k8s.io/v1"
    command = "aws"
    args    = ["eks", "get-token", "--cluster-name", data.terraform_remote_state.network.outputs.cluster_name]
  }
}

provider "helm" {
  kubernetes = {
    host                   = data.terraform_remote_state.network.outputs.cluster_endpoint
    cluster_ca_certificate = base64decode(data.terraform_remote_state.network.outputs.cluster_ca)
    token                  = data.aws_eks_cluster_auth.cluster.token
    exec = {
      api_version = "client.authentication.k8s.io/v1"
      command     = "aws"
      args        = ["eks", "get-token", "--cluster-name", data.terraform_remote_state.network.outputs.cluster_name]

    }
  }
}