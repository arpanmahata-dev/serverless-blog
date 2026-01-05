terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "ap-south-1"  # Mumbai region
}

# ===================================
# DynamoDB Table for Blog Posts
# ===================================

resource "aws_dynamodb_table" "blog_posts" {
  name           = "blog-posts"
  billing_mode   = "PAY_PER_REQUEST"  # On-demand pricing (Free Tier eligible)
  hash_key       = "id"

  attribute {
    name = "id"
    type = "S"
  }

  tags = {
    Name        = "Blog Posts Table"
    Project     = "Serverless-Blog"
    Environment = "Production"
  }
}

# ===================================
# IAM Role for Lambda Functions
# ===================================

resource "aws_iam_role" "lambda_role" {
  name = "serverless_blog_lambda_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name    = "Lambda Blog Role"
    Project = "Serverless-Blog"
  }
}

# IAM Policy for Lambda
resource "aws_iam_role_policy" "lambda_policy" {
  name = "serverless_blog_lambda_policy"
  role = aws_iam_role.lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "dynamodb:PutItem",
          "dynamodb:GetItem",
          "dynamodb:Scan",
          "dynamodb:Query",
          "dynamodb:DeleteItem",
          "dynamodb:UpdateItem",
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "*"
      }
    ]
  })
}

# ===================================
# Lambda Functions
# ===================================

# Create Post Lambda
resource "aws_lambda_function" "create_post" {
  filename         = "create_post.zip"
  function_name    = "blog_create_post"
  role            = aws_iam_role.lambda_role.arn
  handler         = "create_post.lambda_handler"
  runtime         = "python3.11"
  timeout         = 30
  memory_size     = 256

  source_code_hash = filebase64sha256("create_post.zip")

  environment {
    variables = {
      TABLE_NAME = aws_dynamodb_table.blog_posts.name
    }
  }

  tags = {
    Name    = "Create Post Lambda"
    Project = "Serverless-Blog"
  }
}

# Get Posts Lambda
resource "aws_lambda_function" "get_posts" {
  filename         = "get_posts.zip"
  function_name    = "blog_get_posts"
  role            = aws_iam_role.lambda_role.arn
  handler         = "get_posts.lambda_handler"
  runtime         = "python3.11"
  timeout         = 30
  memory_size     = 256

  source_code_hash = filebase64sha256("get_posts.zip")

  environment {
    variables = {
      TABLE_NAME = aws_dynamodb_table.blog_posts.name
    }
  }

  tags = {
    Name    = "Get Posts Lambda"
    Project = "Serverless-Blog"
  }
}

# Get Single Post Lambda
resource "aws_lambda_function" "get_post" {
  filename         = "get_post.zip"
  function_name    = "blog_get_post"
  role            = aws_iam_role.lambda_role.arn
  handler         = "get_post.lambda_handler"
  runtime         = "python3.11"
  timeout         = 30
  memory_size     = 256

  source_code_hash = filebase64sha256("get_post.zip")

  environment {
    variables = {
      TABLE_NAME = aws_dynamodb_table.blog_posts.name
    }
  }

  tags = {
    Name    = "Get Post Lambda"
    Project = "Serverless-Blog"
  }
}

# Delete Post Lambda
resource "aws_lambda_function" "delete_post" {
  filename         = "delete_post.zip"
  function_name    = "blog_delete_post"
  role            = aws_iam_role.lambda_role.arn
  handler         = "delete_post.lambda_handler"
  runtime         = "python3.11"
  timeout         = 30
  memory_size     = 256
  source_code_hash = filebase64sha256("delete_post.zip")
environment {
variables = {
TABLE_NAME = aws_dynamodb_table.blog_posts.name
}
}
tags = {
Name    = "Delete Post Lambda"
Project = "Serverless-Blog"
}
}

# ===================================
# CloudWatch Log Groups
# ===================================
resource "aws_cloudwatch_log_group" "create_post_logs" {
name              = "/aws/lambda/${aws_lambda_function.create_post.function_name}"
retention_in_days = 7
}
resource "aws_cloudwatch_log_group" "get_posts_logs" {
name              = "/aws/lambda/${aws_lambda_function.get_posts.function_name}"
retention_in_days = 7
}
resource "aws_cloudwatch_log_group" "get_post_logs" {
name              = "/aws/lambda/${aws_lambda_function.get_post.function_name}"
retention_in_days = 7
}
resource "aws_cloudwatch_log_group" "delete_post_logs" {
name              = "/aws/lambda/${aws_lambda_function.delete_post.function_name}"
retention_in_days = 7
}
# ===================================
# API Gateway HTTP API
# ===================================
resource "aws_apigatewayv2_api" "blog_api" {
name          = "serverless-blog-api"
protocol_type = "HTTP"
description   = "HTTP API for Serverless Blog"
cors_configuration {
allow_origins = ["*"]
allow_methods = ["GET", "POST", "DELETE", "OPTIONS"]
allow_headers = ["Content-Type", "Authorization"]
max_age       = 300
}
tags = {
Name    = "Blog API"
Project = "Serverless-Blog"
}
}
# ===================================
# API Gateway Integrations
# ===================================
resource "aws_apigatewayv2_integration" "create_post" {
api_id             = aws_apigatewayv2_api.blog_api.id
integration_type   = "AWS_PROXY"
integration_uri    = aws_lambda_function.create_post.invoke_arn
payload_format_version = "2.0"
}
resource "aws_apigatewayv2_integration" "get_posts" {
api_id             = aws_apigatewayv2_api.blog_api.id
integration_type   = "AWS_PROXY"
integration_uri    = aws_lambda_function.get_posts.invoke_arn
payload_format_version = "2.0"
}
resource "aws_apigatewayv2_integration" "get_post" {
api_id             = aws_apigatewayv2_api.blog_api.id
integration_type   = "AWS_PROXY"
integration_uri    = aws_lambda_function.get_post.invoke_arn
payload_format_version = "2.0"
}
resource "aws_apigatewayv2_integration" "delete_post" {
api_id             = aws_apigatewayv2_api.blog_api.id
integration_type   = "AWS_PROXY"
integration_uri    = aws_lambda_function.delete_post.invoke_arn
payload_format_version = "2.0"
}
# ===================================
# API Gateway Routes
# ===================================
resource "aws_apigatewayv2_route" "create_post" {
api_id    = aws_apigatewayv2_api.blog_api.id
route_key = "POST /posts"
target    = "integrations/${aws_apigatewayv2_integration.create_post.id}"
}
resource "aws_apigatewayv2_route" "get_posts" {
api_id    = aws_apigatewayv2_api.blog_api.id
route_key = "GET /posts"
target    = "integrations/${aws_apigatewayv2_integration.get_posts.id}"
}
resource "aws_apigatewayv2_route" "get_post" {
api_id    = aws_apigatewayv2_api.blog_api.id
route_key = "GET /posts/{id}"
target    = "integrations/${aws_apigatewayv2_integration.get_post.id}"
}
resource "aws_apigatewayv2_route" "delete_post" {
api_id    = aws_apigatewayv2_api.blog_api.id
route_key = "DELETE /posts/{id}"
target    = "integrations/${aws_apigatewayv2_integration.delete_post.id}"
}
# ===================================
# API Gateway Stage
# ===================================
resource "aws_apigatewayv2_stage" "default" {
api_id      = aws_apigatewayv2_api.blog_api.id
name        = "$default"
auto_deploy = true
access_log_settings {
destination_arn = aws_cloudwatch_log_group.api_logs.arn
format = jsonencode({
requestId      = "$context.requestId"
ip            = "$context.identity.sourceIp"
requestTime   = "$context.requestTime"
httpMethod    = "$context.httpMethod"
routeKey      = "$context.routeKey"
status        = "$context.status"
protocol      = "$context.protocol"
responseLength = "$context.responseLength"
})
}
tags = {
Name    = "Default Stage"
Project = "Serverless-Blog"
}
}
resource "aws_cloudwatch_log_group" "api_logs" {
name              = "/aws/apigateway/${aws_apigatewayv2_api.blog_api.name}"
retention_in_days = 7
}
# ===================================
# Lambda Permissions for API Gateway
# ===================================
resource "aws_lambda_permission" "create_post" {
statement_id  = "AllowAPIGatewayInvoke"
action        = "lambda:InvokeFunction"
function_name = aws_lambda_function.create_post.function_name
principal     = "apigateway.amazonaws.com"
source_arn    = "${aws_apigatewayv2_api.blog_api.execution_arn}//"
}
resource "aws_lambda_permission" "get_posts" {
statement_id  = "AllowAPIGatewayInvoke"
action        = "lambda:InvokeFunction"
function_name = aws_lambda_function.get_posts.function_name
principal     = "apigateway.amazonaws.com"
source_arn    = "${aws_apigatewayv2_api.blog_api.execution_arn}//"
}
resource "aws_lambda_permission" "get_post" {
statement_id  = "AllowAPIGatewayInvoke"
action        = "lambda:InvokeFunction"
function_name = aws_lambda_function.get_post.function_name
principal     = "apigateway.amazonaws.com"
source_arn    = "${aws_apigatewayv2_api.blog_api.execution_arn}//"
}
resource "aws_lambda_permission" "delete_post" {
statement_id  = "AllowAPIGatewayInvoke"
action        = "lambda:InvokeFunction"
function_name = aws_lambda_function.delete_post.function_name
principal     = "apigateway.amazonaws.com"
source_arn    = "${aws_apigatewayv2_api.blog_api.execution_arn}//"
}
# ===================================
# S3 Bucket for Static Website
# ===================================

# resource "random_id" "bucket_suffix" {
# byte_length = 4
# }
# resource "aws_s3_bucket" "website" {
# bucket = "serverless-blog-${random_id.bucket_suffix.hex}"
# tags = {
# Name    = "Blog Website Bucket"
# Project = "Serverless-Blog"
# }
# }
# resource "aws_s3_bucket_website_configuration" "website" {
# bucket = aws_s3_bucket.website.id
# index_document {
# suffix = "index.html"
# }
# error_document {
# key = "error.html"
# }
# }
# resource "aws_s3_bucket_public_access_block" "website" {
# bucket = aws_s3_bucket.website.id
# block_public_acls       = false
# block_public_policy     = false
# ignore_public_acls      = false
# restrict_public_buckets = false
# }
# resource "aws_s3_bucket_policy" "website" {
# bucket = aws_s3_bucket.website.id
# policy = jsonencode({
# Version = "2012-10-17"
# Statement = [
# {
# Sid       = "PublicReadGetObject"
# Effect    = "Allow"
# Principal = "*" # This was causing the error
# Action    = "s3:GetObject"
# Resource  = "${aws_s3_bucket.website.arn}/"
# }
# ]
# })
# depends_on = [aws_s3_bucket_public_access_block.website]
# }
# ===================================
# Outputs
# ===================================

output "api_endpoint" {
  value       = aws_apigatewayv2_api.blog_api.api_endpoint
  description = "API Gateway endpoint URL - USE THIS IN YOUR FRONTEND"
}

output "instructions" {
  value = <<-EOT
  
  ✅ Serverless Blog Infrastructure Deployed Successfully!
  
  📋 Next Steps:
  
  1. Update frontend with API endpoint:
     API Endpoint: ${aws_apigatewayv2_api.blog_api.api_endpoint}
     
     Edit frontend/index.html and replace:
     const API_URL = 'YOUR_API_GATEWAY_URL_HERE';
     
     With:
     const API_URL = '${aws_apigatewayv2_api.blog_api.api_endpoint}';
  
  2. Open frontend/index.html directly in your browser OR
     Host it on GitHub Pages (free)
  
  3. Test API endpoints:
     - GET ${aws_apigatewayv2_api.blog_api.api_endpoint}/posts
     - POST ${aws_apigatewayv2_api.blog_api.api_endpoint}/posts
  
  EOT
  description = "Instructions for completing the setup"
}