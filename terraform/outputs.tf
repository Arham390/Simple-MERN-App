output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.mern_vpc.id
}

output "public_subnet_ids" {
  description = "IDs of the public subnets"
  value       = aws_subnet.public_subnets[*].id
}

output "mongodb_instance_id" {
  description = "ID of the MongoDB EC2 instance"
  value       = aws_instance.mongodb.id
}

output "mongodb_private_ip" {
  description = "Private IP address of the MongoDB instance"
  value       = aws_instance.mongodb.private_ip
}

output "mern_app_instance_id" {
  description = "ID of the MERN App EC2 instance"
  value       = aws_instance.mern_app.id
}

output "mern_app_public_ip" {
  description = "Public IP address of the MERN App instance"
  value       = aws_instance.mern_app.public_ip
}

output "mern_app_public_dns" {
  description = "Public DNS of the MERN App instance"
  value       = aws_instance.mern_app.public_dns
}

output "ecr_repository_url" {
  description = "URL of the ECR repository"
  value       = aws_ecr_repository.mern_app_repo.repository_url
}

output "ssh_command_mongodb" {
  description = "SSH command to connect to MongoDB instance"
  value       = "ssh -i <path-to-private-key> ubuntu@${aws_instance.mongodb.public_dns}"
}

output "ssh_command_mern_app" {
  description = "SSH command to connect to MERN App instance"
  value       = "ssh -i <path-to-private-key> ubuntu@${aws_instance.mern_app.public_dns}"
}

output "mern_app_url" {
  description = "URL to access the MERN App"
  value       = "http://${aws_instance.mern_app.public_dns}"
}