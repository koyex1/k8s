data "external" "bastion_console" {
  program = ["bash", "-c", <<EOT
aws ec2 get-console-output \
  --instance-id ${aws_instance.bastion.id} \
  --output json | jq '{output: .Output}'
EOT
  ]
}
