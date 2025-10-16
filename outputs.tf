output "api_url" {
  value = "${aws_apigatewayv2_api.api.api_endpoint}/${aws_apigatewayv2_stage.dev.name}"
}

output "s3_website_url" {
  value = aws_s3_bucket_website_configuration.site.website_endpoint
}

output "cloudfront_url" {
  value = "https://${aws_cloudfront_distribution.cdn.domain_name}"
}

output "cloudfront_domain_name" {
  description = "CloudFront distribution domain for DNS CNAME"
  value       = aws_cloudfront_distribution.cdn.domain_name
}

output "api_gateway_domain_name" {
  description = "API Gateway custom domain target for DNS CNAME"
  # if no custom domain, return N/A if has custom domain, return target domain name
  value       = var.api_certificate_arn != "" ? aws_apigatewayv2_domain_name.api[0].domain_name_configuration[0].target_domain_name : "N/A - No custom domain"
}

output "dns_instructions" {
  description = "DNS CNAME records to add to your domain provider"
  value = <<-EOT

  ========================================
  📋 DNS CONFIGURATION REQUIRED
  ========================================

  Add these CNAME records to your DNS provider (Namecheap, Cloudflare, etc.):

  1. CloudFront (Website):
     Type: CNAME
     Host: event
     Value: ${aws_cloudfront_distribution.cdn.domain_name}
     TTL: 300

  2. API Gateway:
     Type: CNAME
     Host: api
     Value: ${var.api_certificate_arn != "" ? aws_apigatewayv2_domain_name.api[0].domain_name_configuration[0].target_domain_name : "N/A"}
     TTL: 300

  ⏱️  Wait 5-10 minutes for DNS propagation
  ✅ Test: https://event.cloudycode.dev

  ========================================
  EOT
}