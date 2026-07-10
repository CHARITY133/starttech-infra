variable "aws_region" {
  description = "AWS region to deploy into"
  type        = string
  default     = "us-east-1"
}

variable "vpc_cidr" {
  type    = string
  default = "10.0.0.0/16"
}

variable "public_subnet_cidrs" {
  type    = list(string)
  default = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_subnet_cidrs" {
  type    = list(string)
  default = ["10.0.11.0/24", "10.0.12.0/24"]
}

variable "eks_cluster_version" {
  type    = string
  default = "1.34"
}

variable "alb_dns_name" {
  description = "DNS name of the backend ALB. Leave empty on first apply (CDN module is skipped); set after k8s Ingress creates the ALB, then re-apply."
  type        = string
  default     = ""
}

variable "cloudfront_distribution_arn" {
  description = "ARN of the CloudFront distribution, used to scope the S3 bucket policy. Leave empty until after the cdn module has run once."
  type        = string
  default     = ""
}
