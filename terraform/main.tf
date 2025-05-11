provider "aws" {
  region = var.aws_region
}

# Create a VPC
resource "aws_vpc" "mern_vpc" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "${var.project_name}-vpc"
  }
}

# Create public subnets
resource "aws_subnet" "public_subnets" {
  count                   = length(var.public_subnet_cidrs)
  vpc_id                  = aws_vpc.mern_vpc.id
  cidr_block              = var.public_subnet_cidrs[count.index]
  availability_zone       = element(var.availability_zones, count.index)
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.project_name}-public-subnet-${count.index + 1}"
  }
}

# Create Internet Gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.mern_vpc.id

  tags = {
    Name = "${var.project_name}-igw"
  }
}

# Create Route Table
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.mern_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "${var.project_name}-public-rt"
  }
}

# Associate Route Table with Subnets
resource "aws_route_table_association" "public_rta" {
  count          = length(var.public_subnet_cidrs)
  subnet_id      = aws_subnet.public_subnets[count.index].id
  route_table_id = aws_route_table.public_rt.id
}

# Create Security Group for EC2 instances
resource "aws_security_group" "ec2_sg" {
  name        = "${var.project_name}-ec2-sg"
  description = "Security group for EC2 instances"
  vpc_id      = aws_vpc.mern_vpc.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "SSH access"
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTP access"
  }

  ingress {
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "MERN app access"
  }

  ingress {
    from_port   = 27017
    to_port     = 27017
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
    description = "MongoDB access"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-ec2-sg"
  }
}

# Create an ECR repository for your MERN app
resource "aws_ecr_repository" "mern_app_repo" {
  name                 = var.ecr_repository_name
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }
}

# IAM Role for EC2 instances to access ECR
resource "aws_iam_role" "ec2_role" {
  name = "${var.project_name}-ec2-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ec2_ecr_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryFullAccess"
  role       = aws_iam_role.ec2_role.name
}


resource "aws_iam_role_policy_attachment" "ec2_ssm_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  role       = aws_iam_role.ec2_role.name
}



# Create IAM Instance Profile
resource "aws_iam_instance_profile" "ec2_profile" {
  name = "${var.project_name}-ec2-profile"
  role = aws_iam_role.ec2_role.name
}

# Key pair for SSH access
resource "aws_key_pair" "mern_key_pair" {
  key_name   = "mern_key_pair"
  public_key = var.public_key
}



# EC2 Instance for MongoDB
resource "aws_instance" "mongodb" {
  ami                    = var.ec2_ami
  instance_type          = var.ec2_instance_type
  subnet_id              = aws_subnet.public_subnets[0].id
  vpc_security_group_ids = [aws_security_group.ec2_sg.id]
  key_name               = aws_key_pair.mern_key_pair.key_name
  iam_instance_profile   = aws_iam_instance_profile.ec2_profile.name

  user_data = <<-EOF
              #!/bin/bash
              sudo apt-get update
              sudo apt-get install -y apt-transport-https ca-certificates curl software-properties-common
              
              # Install Docker
              curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
              sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
              sudo apt-get update
              sudo apt-get install -y docker-ce
              sudo systemctl enable docker
              sudo systemctl start docker
              sudo usermod -aG docker ubuntu
              
              # Run MongoDB Container
              sudo docker run -d --name mongodb -p 27017:27017 -v /data/db:/data/db mongo:latest
              EOF

  root_block_device {
    volume_size = 8
    volume_type = "gp2"
  }

  tags = {
    Name = "${var.project_name}-mongodb"
  }
}

# EC2 Instance for MERN App
resource "aws_instance" "mern_app" {
  ami                    = var.ec2_ami
  instance_type          = var.ec2_instance_type
  subnet_id              = aws_subnet.public_subnets[1].id
  vpc_security_group_ids = [aws_security_group.ec2_sg.id]
  key_name               = aws_key_pair.mern_key_pair.key_name
  iam_instance_profile   = aws_iam_instance_profile.ec2_profile.name
  depends_on             = [aws_instance.mongodb]

  user_data = <<-EOF
              #!/bin/bash
              sudo apt-get update
              sudo apt-get install -y apt-transport-https ca-certificates curl software-properties-common
              
              # Install Docker
              curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
              sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
              sudo apt-get update
              sudo apt-get install -y docker-ce
              sudo systemctl enable docker
              sudo systemctl start docker
              sudo usermod -aG docker ubuntu
              
              # Install AWS CLI
              curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
              sudo apt install -y unzip
              unzip awscliv2.zip
              sudo ./aws/install
              
              # Get login token for ECR
              aws ecr get-login-password --region ${var.aws_region} | docker login --username AWS --password-stdin ${aws_ecr_repository.mern_app_repo.repository_url}
              
              # Wait for the image to be available (usually pushed later via CI/CD)
              # For now, create an environment file for the container
              echo "MONGODB_URI=mongodb://${aws_instance.mongodb.private_ip}:27017/mern-app" > /home/ubuntu/mern-env.list
              echo "NODE_ENV=production" >> /home/ubuntu/mern-env.list
              
              # We'll add a script that can be manually run to pull and start the container
              echo '#!/bin/bash
              aws ecr get-login-password --region ${var.aws_region} | docker login --username AWS --password-stdin ${aws_ecr_repository.mern_app_repo.repository_url}
              docker pull ${aws_ecr_repository.mern_app_repo.repository_url}:latest
              docker stop mern-app || true
              docker rm mern-app || true
              docker run -d --name mern-app -p 80:3000 --env-file /home/ubuntu/mern-env.list ${aws_ecr_repository.mern_app_repo.repository_url}:latest
              ' > /home/ubuntu/start-mern-app.sh
              
              chmod +x /home/ubuntu/start-mern-app.sh
              EOF

  root_block_device {
    volume_size = 8
    volume_type = "gp2"
  }

  tags = {
    Name = "${var.project_name}-app"
  }
}