resource "aws_instance" "bastion" {
  ami                         = var.image_id
  instance_type               = var.instance_type
  subnet_id                   = var.subnet_id
  vpc_security_group_ids      = var.security_groups
  iam_instance_profile        = var.iam_instance_profile_name

# used to assign public ip to the bastion host if it is in a public subnet and we want to access it directly without using ssm session manager. if the bastion host is in a private subnet then we will not assign public ip and we will use ssm session manager to connect to the bastion host.
  associate_public_ip_address = var.associate_public_ip

# key name here is the key pair name.
  key_name = var.key_name

# this is a provisioner that runs a script to install the following listed in the script file: ssm agent, kubectl, aws cli, argocd cli, eksctl cli.
  user_data_base64 = base64encode(var.user_data)

  metadata_options {
    http_tokens = "required" # IMDSv2 enforced
  }

  root_block_device {
    encrypted   = true
    volume_size = 10
  }

  tags = merge(
    var.tags,
    {
      Name = "bastion-${var.env}"
    }
  )
}
#
#resource "aws_eip" "bastion_eip" {
#  count = var.enable_eip ? 1 : 0
#
#  instance = aws_instance.bastion.id
#}

#-------------recommendations -----------
# install ssm agent on the bastion host and use aws cli to connect to the bastion host via its private ip address or its instance id.
# so with ssm which means key_name = null, associate_public_ip_address = false, and enable_eip = false.



# resource "aws_instance" "bastion" {
#   ami                    = var.image_id
#   instance_type          = var.instance_type
#   subnet_id              = var.subnet_id
#   vpc_security_group_ids = var.security_groups
#   tags                   = var.tags
#   key_name               = var.key_name
#   user_data              = var.user_data
#   iam_instance_profile   = var.iam_instance_profile_name
# }