output "instance_public_ip" {
  description = "Public IP address of the EC2 instance"
  value       = aws_eip.app_eip.public_ip
}

output "instance_dns" {
  description = "Public DNS of the EC2 instance"
  value       = aws_instance.mern_app.public_dns
}

output "ecr_repository_url" {
  value       = length(aws_ecr_repository.mern_app) > 0 ? aws_ecr_repository.mern_app[0].repository_url : "ECR repo already exists"
  description = "URL of the ECR repository"
}


output "app_url" {
  description = "URL to access the MERN application"
  value       = "http://${aws_eip.app_eip.public_ip}:3000"
}