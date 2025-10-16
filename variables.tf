variable "aws_region" { default = "eu-north-1" }
variable "project_name" { default = "cloudycode-event" }

# S3 bucket name must be globally unique
variable "bucket_name" { default = "cloudycode-event-site" }

# CORS origins for API Gateway HTTP API
variable "allow_origins" {
  type    = list(string)
  default = ["https://event.cloudycode.dev"]
}

# Custom domain names
variable "cloudfront_domain" {
  description = "Custom domain for CloudFront (frontend)"
  default     = "event.cloudycode.dev"
}

variable "api_domain" {
  description = "Custom domain for API Gateway"
  default     = "api.cloudycode.dev"
}

# ACM Certificate ARNs (must be created manually first)
variable "acm_certificate_arn" {
  description = "ARN of ACM certificate in us-east-1 for CloudFront (*.cloudycode.dev)"
  type        = string
  default     = ""  # Leave empty to use default CloudFront certificate
}

variable "api_certificate_arn" {
  description = "ARN of ACM certificate in eu-north-1 for API Gateway (*.cloudycode.dev)"
  type        = string
  default     = ""  # Leave empty to skip custom domain
}
