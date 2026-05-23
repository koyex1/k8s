variable "vpc_id" {}

variable "allowed_ssh_cidr" {
  description = "CIDR allowed to SSH into bastion"
  type        = list(string)

  # CHANGE THIS IN PROD. to find the ip use this command curl 
  default = ["0.0.0.0/0"]
}

variable "env" {}