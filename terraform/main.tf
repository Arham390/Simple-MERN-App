provider "aws" {
  region = var.aws_region
}

# VPC for the application
resource "aws_vpc" "app_vpc" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true
  
  tags = {
    Name        = "mern-app-vpc"
    Environment = var.environment
  }
}

# Public subnet
resource "aws_subnet" "public_subnet" {
  vpc_id                  = aws_vpc.app_vpc.id
  cidr_block              = cidrsubnet(var.vpc_cidr, 8, 1)
  availability_zone       = "${var.aws_region}a"
  map_public_ip_on_launch = true
  
  tags = {
    Name        = "mern-app-public-subnet"
    Environment = var.environment
  }
}

# Internet Gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.app_vpc.id
  
  tags = {
    Name        = "mern-app-igw"
    Environment = var.environment
  }
}

# Route table for public subnet
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.app_vpc.id
  
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  
  tags = {
    Name        = "mern-app-public-rt"
    Environment = var.environment
  }
}

# Route table association
resource "aws_route_table_association" "public_rta" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.public_rt.id
}

# Security group for EC2 instance
resource "aws_security_group" "app_sg" {
  name        = "mern-app-sg"
  description = "Security group for MERN app"
  vpc_id      = aws_vpc.app_vpc.id
  
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 27017
    to_port     = 27017
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  tags = {
    Name        = "mern-app-sg"
    Environment = var.environment
  }
}

# Get the latest Amazon Linux 2 AMI
data "aws_ami" "amazon_linux_2" {
  most_recent = true
  owners      = ["amazon"]
  
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
  
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# EC2 instance for MERN app
resource "aws_instance" "mern_app" {
  ami                    = data.aws_ami.amazon_linux_2.id
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.public_subnet.id
  vpc_security_group_ids = [aws_security_group.app_sg.id]
  key_name               = var.key_name
  
  user_data = <<-EOF
              #!/bin/bash
              yum update -y
              amazon-linux-extras install docker -y
              service docker start
              systemctl enable docker
              usermod -a -G docker ec2-user
              curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
              chmod +x /usr/local/bin/docker-compose
              yum install -y git
              git clone https://github.com/Arham390/Simple-MERN-App.git /home/ec2-user/mern-app
              chown -R ec2-user:ec2-user /home/ec2-user/mern-app
              cd /home/ec2-user/mern-app
              docker-compose up -d
              EOF
  
  tags = {
    Name        = "mern-app-server"
    Environment = var.environment
  }
}

# Check if the repository already exists using the 'data' source
data "aws_ecr_repository" "mern_app_existing" {
  name = "mern-app"
}

# ECR Repository (create only if it doesn't exist)
resource "aws_ecr_repository" "mern_app" {
  count = try(length(data.aws_ecr_repository.mern_app_existing.id) > 0 ? 0 : 1, 1)
  name  = "mern-app"
  image_tag_mutability = "MUTABLE"
  
  image_scanning_configuration {
    scan_on_push = true
  }
  
  tags = {
    Name        = "mern-app-ecr"
    Environment = var.environment
  }
}

# Elastic IP (optional - free when attached to a running instance)
resource "aws_eip" "app_eip" {
  instance = aws_instance.mern_app.id
  domain   = "vpc"
  
  tags = {
    Name        = "mern-app-eip"
    Environment = var.environment
  }
}
