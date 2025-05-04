provider "aws" {
  region = var.aws_region
}

# EKS Cluster
module "eks" {
  source          = "terraform-aws-modules/eks/aws"
  version         = "19.15.3"
  
  cluster_name    = var.cluster_name
  cluster_version = "1.28"
  
  vpc_id          = module.vpc.vpc_id
  subnet_ids      = module.vpc.private_subnets
  
  eks_managed_node_groups = {
    main = {
      min_size     = 1
      max_size     = 3
      desired_size = 2
      
      instance_types = ["t3.medium"]
    }
  }
}

# VPC for EKS
module "vpc" {
  source = "terraform-aws-modules/vpc/aws"
  version = "5.1.1"
  
  name = "${var.cluster_name}-vpc"
  cidr = "10.0.0.0/16"
  
  azs             = ["${var.aws_region}a", "${var.aws_region}b"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24"]
  
  enable_nat_gateway   = true
  single_nat_gateway   = true
  enable_dns_hostnames = true
  
  public_subnet_tags = {
    "kubernetes.io/role/elb" = "1"
  }
  
  private_subnet_tags = {
    "kubernetes.io/role/internal-elb" = "1"
  }
}

# ECR Repository for Docker images
resource "aws_ecr_repository" "mern_app" {
  name                 = "mern-app"
  image_tag_mutability = "MUTABLE"
  
  image_scanning_configuration {
    scan_on_push = true
  }
}
