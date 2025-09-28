variable "aws_region" { default = "eu-north-1" }
variable "project_name" { default = "abcloud-event" }

# S3 bucket name must be globally unique
variable "bucket_name" { default = "abcloud-event-site" }

# CORS origins for API Gateway HTTP API
variable "allow_origins" {
  type    = list(string)
  default = ["*"] # Replace later with your CloudFront domain for stricter CORS
}