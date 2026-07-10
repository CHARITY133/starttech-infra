output "vpc_id" {
  value = module.networking.vpc_id
}

output "eks_cluster_name" {
  value = module.eks.cluster_name
}

output "eks_cluster_endpoint" {
  value = module.eks.cluster_endpoint
}

output "eks_cluster_security_group_id" {
  value = module.eks.cluster_security_group_id
}

output "s3_frontend_bucket" {
  value = module.storage.bucket_id
}

output "ecr_repository_url" {
  value = module.storage.ecr_repository_url
}

output "redis_endpoint" {
  value = module.database.redis_endpoint
}

output "cloudfront_domain_name" {
  value       = length(module.cdn) > 0 ? module.cdn[0].distribution_domain_name : "not-yet-created (set alb_dns_name and re-apply)"
  description = "The single unified HTTPS domain serving both frontend and /api/*"
}

output "cloudfront_distribution_id" {
  value = length(module.cdn) > 0 ? module.cdn[0].distribution_id : ""
}
