data "terraform_remote_state" "current_state" {
  backend = "s3"

  config = {
    bucket = "eks-olu-tf-state-bucket"
    key    = "security/eks-cluster/dev/terraform.tfstate"
    region = "us-east-1"
  }
}



