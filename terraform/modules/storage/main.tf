############################################
# Storage Module: S3 Static Hosting + ECR
############################################

resource "random_id" "bucket_suffix" {
  byte_length = 4
}

# ---------------- S3 Bucket for Frontend (Private, served via CloudFront OAC) ----------------
resource "aws_s3_bucket" "starttech_frontend_bucket" {
  bucket = "starttech-frontend-bucket-${random_id.bucket_suffix.hex}"

  tags = {
    Name = "starttech-frontend-bucket"
  }
}

resource "aws_s3_bucket_public_access_block" "starttech_frontend_bucket" {
  bucket = aws_s3_bucket.starttech_frontend_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "starttech_frontend_bucket" {
  bucket = aws_s3_bucket.starttech_frontend_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}

# Bucket policy allowing only CloudFront (via OAC) to read objects.
# The CloudFront distribution ARN is injected from the cdn module output
# to avoid a circular dependency; see terraform/main.tf wiring.
resource "aws_s3_bucket_policy" "starttech_frontend_bucket" {
  count  = var.cloudfront_distribution_arn == "" ? 0 : 1
  bucket = aws_s3_bucket.starttech_frontend_bucket.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid       = "AllowCloudFrontServicePrincipalReadOnly"
      Effect    = "Allow"
      Principal = { Service = "cloudfront.amazonaws.com" }
      Action    = "s3:GetObject"
      Resource  = "${aws_s3_bucket.starttech_frontend_bucket.arn}/*"
      Condition = {
        StringEquals = {
          "AWS:SourceArn" = var.cloudfront_distribution_arn
        }
      }
    }]
  })
}

# ---------------- ECR Repository for Backend ----------------
resource "aws_ecr_repository" "starttech_backend_api" {
  name                 = "starttech-backend-api"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Name = "starttech-backend-api"
  }
}
