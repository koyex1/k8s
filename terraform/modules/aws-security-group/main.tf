# Bastion Security Group
module "bastion_sg" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "5.1.0"

  name        = "bastion-sg-${var.env}"
  description = "Allow SSH to Bastion"
  vpc_id      = var.vpc_id

  ingress_rules = ["ssh-tcp"] # in here you fill in type and protocol and port and the string for these 3 if i use a different port number of 667 will be ssh-tcp-667. the protocol and port in the web ui is usually greyed out.

  ingress_cidr_blocks = var.allowed_ssh_cidr #this is the source of the traffic that is allowed to access the bastion host. in this case, we are allowing SSH access from anywhere as indicated by default value of 0.0.0.0

  egress_rules = ["all-all"]

  tags = {
    Name = "bastion-sg-${var.env}"
  }
}

# EKS Cluster Security Group
module "eks_cluster_sg" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "5.1.0"

  name        = "eks-cluster-sg-${var.env}"
  description = "Allow 443 from Bastion only"
  vpc_id      = var.vpc_id

# its is about the resource attached to this security group and not abou the ingress rules of the sg.
  ingress_with_source_security_group_id = [
    {
      from_port                = 443 #ingress_rules = ["https-tcp-443"]
      to_port                  = 443
      protocol                 = "tcp"
      description              = "HTTPS from Bastion"
      source_security_group_id = module.bastion_sg.security_group_id 
    }
  ]

  egress_rules = ["all-all"]

  tags = {
    Name = "eks-cluster-sg-${var.env}"
  }
}


# resource "aws_security_group" "eks-cluster-sg" {
#   name        = "eks-cluster-sg-${var.env}"
#   description = "Allow 443 from Jump Server only"

#   vpc_id = var.vpc_id

#   ingress {
#     from_port       = 443
#     to_port         = 443
#     protocol        = "tcp"
#     security_groups = [aws_security_group.bastion-sg.id]
#   }

#   egress {
#     from_port   = 0
#     to_port     = 0
#     protocol    = "-1"
#     cidr_blocks = ["0.0.0.0/0"]
#   }

#   tags = {
#     Name = "eks-cluster-sg-${var.env}"
#   }
# }

# resource "aws_security_group" "bastion-sg" {
#   name        = "bastion-sg-${var.env}"
#   description = "Allow SSH to Bastion"
#   vpc_id      = var.vpc_id

#   ingress {
#     from_port   = 22
#     to_port     = 22
#     protocol    = "tcp"
#     cidr_blocks = ["0.0.0.0/0"]
#   }

#   egress {
#     from_port   = 0
#     to_port     = 0
#     protocol    = "-1"
#     cidr_blocks = ["0.0.0.0/0"]
#   }

#   tags = {
#     Name = "bastion-sg-${var.env}"
#   }
# }