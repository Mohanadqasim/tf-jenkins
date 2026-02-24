output "security_group_id" {
  value = aws_security_group.tf_jenkins_sg.id
}

output "key_name" {
  value = aws_key_pair.tf_jenkins_key.key_name
}

output "ecr_repository_url" {
  value = aws_ecr_repository.tf_jenkins_ecr.repository_url
}

output "ec2_public_ip" {
  value = aws_instance.tf_jenkins_ec2.public_ip
}