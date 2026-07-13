terraform {
  required_version = ">= 1.6.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }

  backend "s3" {
    bucket         = "starttech-tfstate-427882481715"
    key            = "starttech-infra/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "starttech-tfstate-lock"
    encrypt        = true
  }
}

provider "aws" {
  region = var.aws_region
}

############################################
# Networking
############################################
module "networking" {
  source = "./modules/networking"

  vpc_cidr             = var.vpc_cidr
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
}

############################################
# EKS
############################################
module "eks" {
  source = "./modules/eks"

  cluster_version     = var.eks_cluster_version
  node_instance_types = var.node_instance_types
  public_subnet_ids   = module.networking.public_subnet_ids
  private_subnet_ids  = module.networking.private_subnet_ids
}

############################################
# Storage (S3 frontend bucket + ECR)
#
# NOTE ON TWO-PASS APPLY:
# The S3 bucket policy needs the CloudFront distribution ARN, and CloudFront
# needs the S3 bucket's domain name -> no circular dependency there (S3 is
# created first, CDN references it). But CloudFront ALSO needs the ALB's DNS
# name, and the ALB is created by the AWS Load Balancer Controller running
# INSIDE the cluster (via k8s/ingress.yaml), which only exists after you've
# deployed the app. So the flow is:
#   1. terraform apply -target=module.networking -target=module.eks \
#        -target=module.storage -target=module.database
#   2. Deploy the AWS Load Balancer Controller + kubectl apply -f k8s/
#      (creates the ALB) and grab its DNS name:
#        kubectl get ingress backend-ingress -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'
#   3. Set alb_dns_name in terraform.tfvars to that value and run
#      `terraform apply` again to create/update the CloudFront distribution
#      and attach the S3 bucket policy.
# This is expected and is documented in scripts/deploy-infrastructure.sh.
############################################
module "storage" {
  source = "./modules/storage"

  cloudfront_distribution_arn = var.cloudfront_distribution_arn
}

############################################
# CDN (only created once we have a real ALB DNS name)
############################################
module "cdn" {
  source = "./modules/cdn"
  count  = var.alb_dns_name == "" ? 0 : 1

  s3_bucket_regional_domain_name = module.storage.bucket_regional_domain_name
  alb_dns_name                   = var.alb_dns_name
}

############################################
# Database (ElastiCache Redis)
############################################
module "database" {
  source = "./modules/database"

  vpc_id                         = module.networking.vpc_id
  private_subnet_ids             = module.networking.private_subnet_ids
  eks_cluster_security_group_id  = module.eks.cluster_security_group_id
}
