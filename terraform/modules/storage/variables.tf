variable "cloudfront_distribution_arn" {
  description = "ARN of the CloudFront distribution allowed to read from this bucket (set after cdn module creates it; see root main.tf two-pass wiring note in README)"
  type        = string
  default     = ""
}
