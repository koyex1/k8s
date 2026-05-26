data "terraform_remote_state" "network" {
  backend = "s3"

  config = {
    bucket = "my-terraform-state-bucket"
    key    = "network/terraform.tfstate"
    region = "eu-west-1"
  }
}


data "aws_eks_cluster_auth" "cluster" {
  name = data.terraform_remote_state.network.outputs.cluster_name
}

data "aws_eks_cluster" "cluster" {
  name = data.terraform_remote_state.network.outputs.cluster_name
}
