output "bucket_id" {
  value = aws_s3_bucket.starttech_frontend_bucket.id
}

output "bucket_arn" {
  value = aws_s3_bucket.starttech_frontend_bucket.arn
}

output "bucket_regional_domain_name" {
  value = aws_s3_bucket.starttech_frontend_bucket.bucket_regional_domain_name
}

output "ecr_repository_url" {
  value = aws_ecr_repository.starttech_backend_api.repository_url
}

output "ecr_repository_name" {
  value = aws_ecr_repository.starttech_backend_api.name
}
