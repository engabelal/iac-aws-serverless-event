aws_region    = "eu-north-1"
project_name  = "cloudycode-event"
bucket_name   = "event.cloudycode.dev"
allow_origins = ["https://event.cloudycode.dev"]

# Custom domains
cloudfront_domain = "event.cloudycode.dev"
api_domain        = "api.cloudycode.dev"

# ACM Certificate ARNs
acm_certificate_arn = "arn:aws:acm:us-east-1:501235162976:certificate/5874885b-8dc6-46b3-abd9-cbac4f77a961"
api_certificate_arn = "arn:aws:acm:eu-north-1:501235162976:certificate/aa53eb65-06f9-4eb8-9213-d48d44391c47"
