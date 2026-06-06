output "bastion_id" {
  value = aws_instance.bastion.id
}

output "public_ip" {
  #value = try(aws_eip.bastion_eip[0].public_ip, null)
  value = "nothing for now"
}

output "private_ip" {
  value = aws_instance.bastion.private_ip
}

output "bastion_public_ip" {
  value = aws_instance.bastion.public_ip
  description = "Public IP address of the bastion host"
}

output "bastion_console_output" {
  value = data.external.bastion_console.result.output
}

