# 🎟️ Serverless Event Registration System

Production-ready serverless event registration and raffle system built with AWS and Terraform.

![Terraform](https://img.shields.io/badge/Terraform-7B42BC?style=flat-square&logo=terraform&logoColor=white)
![AWS Lambda](https://img.shields.io/badge/AWS%20Lambda-FF9900?style=flat-square&logo=awslambda&logoColor=white)
![API Gateway](https://img.shields.io/badge/API%20Gateway-880075?style=flat-square&logo=amazonaws&logoColor=white)
![DynamoDB](https://img.shields.io/badge/DynamoDB-4053D6?style=flat-square&logo=amazondynamodb&logoColor=white)
![S3](https://img.shields.io/badge/S3-569A31?style=flat-square&logo=amazons3&logoColor=white)
![CloudFront](https://img.shields.io/badge/CloudFront-FF4F8B?style=flat-square&logo=amazonaws&logoColor=white)

---

## 📐 Architecture

```
User → CloudFront CDN → S3 Static Website → API Gateway → Lambda → DynamoDB
```

![Architecture Diagram](images/event-registration-aws-architecture.png)

**Components:**
- **Frontend**: S3 + CloudFront with custom domain
- **Backend**: API Gateway HTTP API + Lambda (Node.js 20.x)
- **Database**: DynamoDB (pay-per-request)
- **Security**: ACM certificates, HTTPS, CORS

---

## ✨ Features

- ✅ Event registration with email/name
- ✅ Random winner selection (3 winners)
- ✅ Participant count tracking
- ✅ Custom domain support (CloudFront + API Gateway)
- ✅ CORS enabled
- ✅ Infrastructure as Code (Terraform)

---

## 🚀 Quick Start

### Prerequisites
- AWS CLI configured
- Terraform >= 1.5
- Node.js 20.x

### Deploy

```bash
# 1. Initialize
terraform init

# 2. Plan
terraform plan

# 3. Deploy
terraform apply -auto-approve

# 4. Get URLs
terraform output
```

### Outputs
```
api_url         = "https://abc123.execute-api.eu-north-1.amazonaws.com/dev"
s3_website_url  = "http://cloudycode-event-site.s3-website.eu-north-1.amazonaws.com"
cloudfront_url  = "https://d1234abcd.cloudfront.net"
```

---

## ⚙️ Configuration

### Basic Setup (`terraform.tfvars`)

```hcl
aws_region    = "eu-north-1"
project_name  = "cloudycode-event"
bucket_name   = "cloudycode-event-site"
allow_origins = ["*"]
```

### With Custom Domains

```hcl
aws_region    = "eu-north-1"
project_name  = "cloudycode-event"
bucket_name   = "event.cloudycode.dev"  # Must match CloudFront domain

# Custom domains
cloudfront_domain = "event.cloudycode.dev"
api_domain        = "api.cloudycode.dev"

# ACM certificates
acm_certificate_arn = "arn:aws:acm:us-east-1:123456789012:certificate/abc-123"
api_certificate_arn = "arn:aws:acm:eu-north-1:123456789012:certificate/xyz-789"

# CORS
allow_origins = ["https://event.cloudycode.dev"]
```

---

## 🌐 CloudFront Configuration

### Price Classes

```hcl
price_class = "PriceClass_100"
```

| Class | Coverage | Cost | Use Case |
|-------|----------|------|----------|
| `PriceClass_100` | US, Canada, Europe | 💰 Cheapest | Regional apps |
| `PriceClass_200` | + Asia, Middle East | 💰💰 Medium | Multi-regional |
| `PriceClass_All` | All edge locations | 💰💰💰 Highest | Global apps |

**Current**: `PriceClass_100` (most cost-effective for EU/NA)

### Cache Policy

```hcl
cache_policy_id = "658327ea-f89d-4fab-a63d-7e88639e58f6"  # CachingOptimized
```

**AWS Managed Policies:**
- `CachingDisabled` - No caching (dynamic content)
- `CachingOptimized` - ✅ Recommended (static websites)
- `CachingOptimizedForUncompressedObjects` - Large files

Get full list:
```bash
aws cloudfront list-cache-policies --type managed
```

---

## 🔒 SSL/TLS Certificates

### Certificate Requirements

| Service | Region | Domain |
|---------|--------|--------|
| CloudFront | **us-east-1** (required) | `event.cloudycode.dev` |
| API Gateway | Deployment region | `api.cloudycode.dev` |

### Setup Steps

**1. Request CloudFront Certificate (us-east-1)**
```bash
aws acm request-certificate \
  --domain-name event.cloudycode.dev \
  --validation-method DNS \
  --region us-east-1
```

**2. Request API Gateway Certificate (eu-north-1)**
```bash
aws acm request-certificate \
  --domain-name api.cloudycode.dev \
  --validation-method DNS \
  --region eu-north-1
```

**3. Validate Certificates**
- Go to ACM Console → Create DNS records
- Or add CNAME records manually to DNS provider
- Wait for status: "Issued"

**4. Update terraform.tfvars**
```hcl
acm_certificate_arn = "arn:aws:acm:us-east-1:123456789012:certificate/abc-123"
api_certificate_arn = "arn:aws:acm:eu-north-1:123456789012:certificate/xyz-789"
```

**5. Deploy**
```bash
terraform apply -auto-approve
```

---

## 🌍 Real-World Example: cloudycode.dev

### Actual Production Setup

**Domain Structure:**
```
Website:  event.cloudycode.dev  → CloudFront → S3
API:      api.cloudycode.dev    → API Gateway → Lambda
```

**Configuration:**
```hcl
# terraform.tfvars
aws_region    = "eu-north-1"
project_name  = "cloudycode-event"
bucket_name   = "event.cloudycode.dev"

cloudfront_domain = "event.cloudycode.dev"
api_domain        = "api.cloudycode.dev"

acm_certificate_arn = "arn:aws:acm:us-east-1:123456789012:certificate/abc-123"
api_certificate_arn = "arn:aws:acm:eu-north-1:123456789012:certificate/xyz-789"

allow_origins = ["https://event.cloudycode.dev"]
```

**DNS Records (Route53):**
```hcl
# CloudFront A record
resource "aws_route53_record" "cloudfront" {
  zone_id = data.aws_route53_zone.main.zone_id
  name    = "event.cloudycode.dev"
  type    = "A"
  
  alias {
    name                   = aws_cloudfront_distribution.cdn.domain_name
    zone_id                = aws_cloudfront_distribution.cdn.hosted_zone_id
    evaluate_target_health = false
  }
}

# CloudFront AAAA record (IPv6)
resource "aws_route53_record" "cloudfront_ipv6" {
  zone_id = data.aws_route53_zone.main.zone_id
  name    = "event.cloudycode.dev"
  type    = "AAAA"
  
  alias {
    name                   = aws_cloudfront_distribution.cdn.domain_name
    zone_id                = aws_cloudfront_distribution.cdn.hosted_zone_id
    evaluate_target_health = false
  }
}

# API Gateway A record
resource "aws_route53_record" "api" {
  zone_id = data.aws_route53_zone.main.zone_id
  name    = "api.cloudycode.dev"
  type    = "A"
  
  alias {
    name                   = aws_apigatewayv2_domain_name.api[0].domain_name_configuration[0].target_domain_name
    zone_id                = aws_apigatewayv2_domain_name.api[0].domain_name_configuration[0].hosted_zone_id
    evaluate_target_health = false
  }
}
```

**Testing:**
```bash
# Website
curl -I https://event.cloudycode.dev

# API
curl https://api.cloudycode.dev/count
```

---

## 📡 API Endpoints

**Base URL:**
```
https://api.cloudycode.dev
# Or default:
https://abc123.execute-api.eu-north-1.amazonaws.com/dev
```

### 1. Register
```bash
POST /register
Content-Type: application/json

{
  "email": "user@example.com",
  "name": "John Doe",
  "event": "Tech Conference 2024"
}

# Response
{
  "message": "Registration successful!",
  "email": "user@example.com"
}
```

### 2. Count
```bash
GET /count

# Response
{
  "count": 156
}
```

### 3. Pick Winners
```bash
GET /pick_winners

# Response
{
  "winners": [
    {"email": "winner1@example.com", "name": "Person 1"},
    {"email": "winner2@example.com", "name": "Person 2"},
    {"email": "winner3@example.com", "name": "Person 3"}
  ]
}
```

---

## 📁 Project Structure

```
Serverless-Event-Registration/
├── main.tf                 # Infrastructure code
├── variables.tf            # Input variables
├── outputs.tf              # Output values
├── providers.tf            # AWS provider
├── terraform.tfvars        # Configuration
├── images/
│   ├── event-registration-aws-architecture.png
│   ├── register_page.png
│   ├── winner_page.png
│   └── dynamodb_winner.png
├── lambdas/
│   ├── register.js
│   ├── count.js
│   ├── pick_winners.js
│   └── *.zip              # Auto-generated
└── web/
    ├── register.html
    ├── winners.html
    └── config.json        # Auto-generated
```

---

## 📸 Screenshots

### Registration Page
![Registration](images/register_page.png)

### Winners Page
![Winners](images/winner_page.png)

### DynamoDB Table
![DynamoDB](images/dynamodb_winner.png)

---

## 🔧 Useful Commands

### CloudFront
```bash
# List cache policies
aws cloudfront list-cache-policies --type managed \
  --query 'CachePolicyList.Items[*].[Name,Id]' --output table

# Invalidate cache
aws cloudfront create-invalidation \
  --distribution-id E1234ABCD \
  --paths "/*"
```

### ACM Certificates
```bash
# Check CloudFront cert (us-east-1)
aws acm describe-certificate \
  --certificate-arn arn:aws:acm:us-east-1:123456789012:certificate/abc-123 \
  --region us-east-1

# Check API cert (regional)
aws acm describe-certificate \
  --certificate-arn arn:aws:acm:eu-north-1:123456789012:certificate/xyz-789 \
  --region eu-north-1
```

### Testing
```bash
# Get API URL
API_URL=$(terraform output -raw api_url)

# Test endpoints
curl $API_URL/count
curl -X POST $API_URL/register \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","name":"Test","event":"Conference"}'
curl $API_URL/pick_winners
```

### Lambda Logs
```bash
# Tail logs
aws logs tail /aws/lambda/cloudycode-event_register --follow
aws logs tail /aws/lambda/cloudycode-event_count --follow
aws logs tail /aws/lambda/cloudycode-event_pick_winners --follow
```

---

## 💰 Cost Estimation

| Service | Usage | Monthly Cost |
|---------|-------|--------------|
| DynamoDB | 10K requests | ~$2.50 |
| Lambda | 1M requests | ~$0.20 |
| API Gateway | 1M requests | ~$1.00 |
| S3 | 1GB + 10K requests | ~$0.05 |
| CloudFront | 10GB (PriceClass_100) | ~$0.85 |
| Route53 | 1 hosted zone | ~$0.50 |
| ACM | Certificates | **FREE** |
| CloudWatch | 1GB logs | ~$0.50 |

**Total**: ~$5.60/month

---

## 🛡️ Security

### Current Setup
✅ HTTPS enforced  
✅ S3 bucket policy (GetObject only)  
✅ Lambda IAM least privilege  
✅ CORS configured  
✅ TLS 1.2+ enforced  

### Production Recommendations
- [ ] CloudFront WAF
- [ ] API Gateway throttling
- [ ] Lambda KMS encryption
- [ ] CloudTrail logging
- [ ] Restrict CORS origins
- [ ] DynamoDB point-in-time recovery
- [ ] API authentication (Cognito)
- [ ] CloudWatch alarms

---

## 🧹 Cleanup

```bash
# Destroy infrastructure
terraform destroy -auto-approve

# Delete Lambda logs (not managed by Terraform)
aws logs delete-log-group --log-group-name "/aws/lambda/cloudycode-event_register"
aws logs delete-log-group --log-group-name "/aws/lambda/cloudycode-event_count"
aws logs delete-log-group --log-group-name "/aws/lambda/cloudycode-event_pick_winners"

# Empty S3 bucket if needed
aws s3 rm s3://event.cloudycode.dev --recursive
```

---

## 🛠️ Troubleshooting

### S3 Access Denied
- Check public access block is disabled
- Verify bucket policy allows GetObject
- Check organization SCPs

### CloudFront Certificate Error
- Certificate MUST be in us-east-1
- Certificate must cover domain in aliases
- Wait for validation to complete

### API Gateway Certificate Error
- API cert must be in deployment region
- CloudFront cert must be in us-east-1
- Don't mix them up!

### CORS Error
- Check `allow_origins` in terraform.tfvars
- Verify API Gateway CORS config
- Clear browser cache

### Winners Already Selected
- Lambda locks winners after first draw
- Delete DynamoDB items to reset
- Or deploy fresh stack

---

## 📚 Resources

- [CloudFront Pricing](https://aws.amazon.com/cloudfront/pricing/)
- [ACM Validation](https://docs.aws.amazon.com/acm/latest/userguide/dns-validation.html)
- [CloudFront Cache Policies](https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/using-managed-cache-policies.html)
- [API Gateway Custom Domains](https://docs.aws.amazon.com/apigateway/latest/developerguide/how-to-custom-domains.html)
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)

---

## 👨‍💻 Author

**Ahmed Belal** - DevOps Engineer  
GitHub: [@engabelal](https://github.com/engabelal)

---

## 📝 License

MIT License - Copyright (c) 2024 Ahmed Belal

---

**🎉 Happy Event Registration!**
