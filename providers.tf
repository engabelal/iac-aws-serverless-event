terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws     = { source = "hashicorp/aws", version = "~> 5.0" }
    local   = { source = "hashicorp/local", version = "~> 2.0" }
    archive = { source = "hashicorp/archive", version = "~> 2.4" }
  }
}

provider "aws" {
  region = var.aws_region
}

# CloudFront requires ACM certificates in us-east-1
provider "aws" {
  # the certificate must be in us-east-1
  alias  = "us_east_1"
  region = "us-east-1"
}
