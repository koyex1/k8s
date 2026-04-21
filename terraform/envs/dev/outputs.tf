output "ami_id_amazon_filtered" {
    value = data.aws_ami.amazon_linux.id
}

output "ami_id_ubuntu_filtered" {
    value = data.aws_ami.ubuntu.id
}