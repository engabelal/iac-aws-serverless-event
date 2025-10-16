aws_region    = "eu-north-1"
project_name  = "cloudycode-event"
bucket_name   = "cloudycode-event-site"
allow_origins = ["https://event.cloudycode.dev"]

# Custom domains
cloudfront_domain = "event.cloudycode.dev"
api_domain        = "api.cloudycode.dev"

# ACM Certificate ARNs - Add these after creating certificates
# acm_certificate_arn = "arn:aws:acm:us-east-1:ACCOUNT_ID:certificate/CERT_ID"
# api_certificate_arn = "arn:aws:acm:eu-north-1:ACCOUNT_ID:certificate/CERT_ID"
