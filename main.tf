#######################################
# 1. DynamoDB Table
#######################################
resource "aws_dynamodb_table" "db" {
  name         = "${var.project_name}_db"
  billing_mode = "PAY_PER_REQUEST" # On-demand pricing
  hash_key     = "email" # Partition key
  range_key    = "event" # Without this, one email could only be stored once in the table

  attribute {
    name = "email" # Partition key
    type = "S" # S = String
  }

  attribute {
    name = "event" # Sort key
    type = "S"  # S = String
  }

  tags = {
    project = var.project_name  # Tag for easier identification
  }
}

#######################################
# 2. IAM Role for Lambda Functions 
#######################################
resource "aws_iam_role" "lambda_role" {
  name = "${var.project_name}-lambda-role" # Role name

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })
}

# Attach DynamoDB Full Access
resource "aws_iam_role_policy_attachment" "ddb_full" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonDynamoDBFullAccess"
}

# Attach CloudWatch Logs Access
resource "aws_iam_role_policy_attachment" "cw_logs" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchLogsFullAccess"
}

#######################################
# 3. Lambda Functions
#######################################
# Archive zips for Lambda functions
data "archive_file" "register_zip" { 
  type        = "zip" 
  source_file = "${path.module}/lambdas/register.js"
  output_path = "${path.module}/lambdas/register.zip"
}

data "archive_file" "count_zip" {
  type        = "zip"
  source_file = "${path.module}/lambdas/count.js"
  output_path = "${path.module}/lambdas/count.zip"
}

data "archive_file" "pick_zip" {
  type        = "zip"
  source_file = "${path.module}/lambdas/pick_winners.js"
  output_path = "${path.module}/lambdas/pick_winners.zip"
}

# Lambda: Register function Creation
resource "aws_lambda_function" "register" {
  function_name    = "${var.project_name}_register"
  role             = aws_iam_role.lambda_role.arn
  runtime          = "nodejs20.x" 
  handler          = "register.handler" # runtime management configuration selected in the AWS Lambda console
  filename         = data.archive_file.register_zip.output_path
  source_code_hash = data.archive_file.register_zip.output_base64sha256 # Ensure Lambda is updated only when the zipped code changes (trigger redeploy on code change)

  environment { 
    variables = {
      TABLE_NAME = aws_dynamodb_table.db.name # Pass DynamoDB table name to Lambda; in JS it's read with: const TABLE = process.env.TABLE_NAME;
    }
  }
}

# Lambda: Count function Creation
resource "aws_lambda_function" "count" {
  function_name    = "${var.project_name}_count"
  role             = aws_iam_role.lambda_role.arn
  runtime          = "nodejs20.x"
  handler          = "count.handler"
  filename         = data.archive_file.count_zip.output_path
  source_code_hash = data.archive_file.count_zip.output_base64sha256

  environment {
    variables = {
      TABLE_NAME = aws_dynamodb_table.db.name
    }
  }
}

# Lambda: Pick Winners function Creation
resource "aws_lambda_function" "pick" {
  function_name    = "${var.project_name}_pick_winners"
  role             = aws_iam_role.lambda_role.arn
  runtime          = "nodejs20.x"
  handler          = "pick_winners.handler"
  filename         = data.archive_file.pick_zip.output_path
  source_code_hash = data.archive_file.pick_zip.output_base64sha256

  environment {
    variables = {
      TABLE_NAME = aws_dynamodb_table.db.name
    }
  }
}

#######################################
# 4. API Gateway
#######################################
resource "aws_apigatewayv2_api" "api" {
  name          = "${var.project_name}-api"
  protocol_type = "HTTP"

  cors_configuration { # Enable CORS
    allow_headers = ["*"]
    allow_methods = ["GET", "POST"]
    allow_origins = var.allow_origins # e.g. ["*"] or ["https://xxxx.cloudfront.net"]
  }
}

resource "aws_apigatewayv2_stage" "dev" { # Deployment stage
  api_id      = aws_apigatewayv2_api.api.id
  name        = "dev" # Stage name will appear in the URL (e.g. /dev)
  auto_deploy = true # Auto-deploy on changes
}

# Integrations
resource "aws_apigatewayv2_integration" "register" {
  api_id                 = aws_apigatewayv2_api.api.id 
  integration_type       = "AWS_PROXY" # Lambda proxy integration
  integration_uri        = aws_lambda_function.register.arn
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_integration" "count" {
  api_id                 = aws_apigatewayv2_api.api.id
  integration_type       = "AWS_PROXY"
  integration_uri        = aws_lambda_function.count.arn
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_integration" "pick" {
  api_id                 = aws_apigatewayv2_api.api.id
  integration_type       = "AWS_PROXY"
  integration_uri        = aws_lambda_function.pick.arn
  payload_format_version = "2.0"
}

# Routes
resource "aws_apigatewayv2_route" "register" {
  api_id    = aws_apigatewayv2_api.api.id
  route_key = "POST /register" # POST method for /register endpoint
  target    = "integrations/${aws_apigatewayv2_integration.register.id}" # Link to the integration
}

resource "aws_apigatewayv2_route" "count" {
  api_id    = aws_apigatewayv2_api.api.id
  route_key = "GET /count" # GET method for /count endpoint
  target    = "integrations/${aws_apigatewayv2_integration.count.id}" # Link to the integration 
}

resource "aws_apigatewayv2_route" "pick" {
  api_id    = aws_apigatewayv2_api.api.id
  route_key = "GET /pick_winners" # GET method for /pick_winners endpoint
  target    = "integrations/${aws_apigatewayv2_integration.pick.id}" # Link to the integration
}

# Permissions for Lambda invocation
resource "aws_lambda_permission" "perm_register" { # Allow API Gateway to invoke Lambda
  statement_id  = "AllowInvokeRegister"
  action        = "lambda:InvokeFunction" 
  function_name = aws_lambda_function.register.function_name 
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.api.execution_arn}/*/*"
}

resource "aws_lambda_permission" "perm_count" {
  statement_id  = "AllowInvokeCount"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.count.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.api.execution_arn}/*/*"
}

resource "aws_lambda_permission" "perm_pick" {
  statement_id  = "AllowInvokePick"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.pick.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.api.execution_arn}/*/*"
}

#######################################
# 5. S3 Website Hosting
#######################################
resource "aws_s3_bucket" "site" { # S3 bucket for website hosting
  bucket = var.bucket_name
}

resource "aws_s3_bucket_public_access_block" "site" { # Make the bucket public
  bucket = aws_s3_bucket.site.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_website_configuration" "site" { # Enable static website hosting
  bucket = aws_s3_bucket.site.id

  index_document {
    suffix = "register.html" # Default document
  }
}

resource "aws_s3_bucket_policy" "public" { # Public read access policy
  bucket = aws_s3_bucket.site.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Sid       = "PublicRead",
      Effect    = "Allow",
      Principal = "*",
      Action    = ["s3:GetObject"],
      Resource  = ["${aws_s3_bucket.site.arn}/*"] #wildcard to allow access to all objects in the bucket ( get from aws s3_bucket site )
    }]
  })

  depends_on = [aws_s3_bucket_public_access_block.site] # Ensure public access block is disabled first
}

# Generate config.json automatically
resource "local_file" "frontend_config" { # Local file to hold config.json
  content  = jsonencode({ api_url = "${aws_apigatewayv2_api.api.api_endpoint}/${aws_apigatewayv2_stage.dev.name}" }) # API URL for frontend to call to the HTML files to be automatically updated with the correct API URL
  filename = "${path.module}/web/config.json" # Save in the web directory on local machine
}

# Upload frontend files
resource "aws_s3_object" "register_html" {
  bucket       = aws_s3_bucket.site.id
  key          = "register.html"
  source       = "${path.module}/web/register.html"
  content_type = "text/html"
  etag         = filemd5("${path.module}/web/register.html") # Ensure S3 object is updated only when the file changes (trigger redeploy on code change)
}

resource "aws_s3_object" "winners_html" {
  bucket       = aws_s3_bucket.site.id
  key          = "winners.html"
  source       = "${path.module}/web/winners.html"
  content_type = "text/html"
  etag         = filemd5("${path.module}/web/winners.html")
}

resource "aws_s3_object" "config_json" { # Upload the generated config.json to S3 so frontend can access it automatically as a variable from const res = await fetch("config.json"); on HTML side
  bucket       = aws_s3_bucket.site.id
  key          = "config.json"
  content      = jsonencode({ api_url = "${aws_apigatewayv2_api.api.api_endpoint}/${aws_apigatewayv2_stage.dev.name}" }) # Use the same content as the local file
  content_type = "application/json"
  etag         = md5(jsonencode({ api_url = "${aws_apigatewayv2_api.api.api_endpoint}/${aws_apigatewayv2_stage.dev.name}" }))
  depends_on   = [local_file.frontend_config] # Ensure local file is created first
}

#######################################
# 6. CloudFront Distribution (Optional)
#######################################
resource "aws_cloudfront_distribution" "cdn" {
  enabled             = true
  default_root_object = "register.html"

  origin { # S3 website endpoint as origin
    domain_name = aws_s3_bucket_website_configuration.site.website_endpoint
    origin_id   = "s3-website-${aws_s3_bucket.site.bucket}"

    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "http-only"
      origin_ssl_protocols   = ["TLSv1.2"]
    }
  }

  default_cache_behavior { # Cache behavior settings
    target_origin_id       = "s3-website-${aws_s3_bucket.site.bucket}"
    viewer_protocol_policy = "redirect-to-https"
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]
    cache_policy_id        = "658327ea-f89d-4fab-a63d-7e88639e58f6" # AWS managed: CachingOptimized you can get with " aws cloudfront list-cache-policies --type managed "
    # AWS managed cache policies: 
    # 1. CachingDisabled, 2. CachingOptimized (recommended), 3. CachingOptimizedForUncompressedObjects
  }

  price_class = "PriceClass_100" 
  # CloudFront price classes:
    # 1. PriceClass_100 → Only US, Canada, Europe (cheapest)
    # 2. PriceClass_200 → Adds Asia & Middle East (medium cost)
    # 3. PriceClass_All → All edge locations worldwide (highest cost)
    # Here we use PriceClass_100 as the most cost-effective option

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }

  tags = {
    project = var.project_name
  }
}
