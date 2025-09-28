output "api_url" {
  # Example: https://xxxx.execute-api.eu-north-1.amazonaws.com/dev
  value = "${aws_apigatewayv2_api.api.api_endpoint}/${aws_apigatewayv2_stage.dev.name}"
}

output "s3_website_url" {
  # Example: http://<bucket>.s3-website.<region>.amazonaws.com
  value = aws_s3_bucket_website_configuration.site.website_endpoint
}

output "cloudfront_url" {
  # Example: https://xxxx.cloudfront.net
  value = "https://${aws_cloudfront_distribution.cdn.domain_name}"
}