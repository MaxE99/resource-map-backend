resource "aws_iam_role" "lambda_role" {
  name = "lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Project = var.project
    Name    = "Lambda IAM Role"
  }
}

resource "aws_iam_policy" "dynamodb_lambda_policy" {
  name        = "dynamodb_lambda_policy"
  description = "Allows Lambda to access DynamoDB"
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Action" : [
          "dynamodb:BatchGetItem",
          "dynamodb:GetItem",
          "dynamodb:Query",
          "dynamodb:Scan"
        ],
        "Resource" : [
          var.dynamodb_arn,
          "${var.dynamodb_arn}/index/*"
        ]
      }
    ]
  })

  tags = {
    Project = var.project
    Name    = "Lambda DynamoDB Policy"
  }
}

resource "aws_iam_role_policy_attachment" "lambda_basic" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
  role       = aws_iam_role.lambda_role.name
}

resource "aws_iam_role_policy_attachment" "lambda_dynamodb" {
  policy_arn = aws_iam_policy.dynamodb_lambda_policy.arn
  role       = aws_iam_role.lambda_role.name
}

resource "aws_api_gateway_rest_api" "main" {
  name = "${var.project}-api-gateway"

  endpoint_configuration {
    types = ["REGIONAL"]
  }

  tags = {
    Project = var.project
    Name    = "Main API Gateway"
  }
}

resource "aws_cloudfront_distribution" "api_gateway" {
  enabled = true

  origin {
    domain_name = var.api_domain
    origin_id   = "api-gateway-origin"
    custom_origin_config {
        http_port              = 80
        https_port             = 443
        origin_protocol_policy = "https-only"
        origin_ssl_protocols   = ["TLSv1.2"]
    }
  }

  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD", "OPTIONS"]
    cached_methods   = ["GET", "HEAD", "OPTIONS"]
    target_origin_id = "api-gateway-origin"

    forwarded_values {
      query_string = true

      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 3600
    default_ttl            = 86400
    max_ttl                = 604800
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    acm_certificate_arn            = var.acm_certificate_arn
    ssl_support_method             = "sni-only"
    cloudfront_default_certificate = false
  }

  price_class = "PriceClass_100"

  tags = {
    Project = var.project
    Name    = "APIGateway Cloudfront Distribution"
  }
}

module "lambda_endpoints" {
  source = "../endpoint"
  count  = 5

  project                  = var.project
  path                     = element(["production", "reserves", "gov_info", "prices", "balance"], count.index)
  lambda_role_arn          = aws_iam_role.lambda_role.arn
  rest_api_id              = aws_api_gateway_rest_api.main.id
  rest_api_root_resource_id = aws_api_gateway_rest_api.main.root_resource_id
  rest_api_execution_arn   = aws_api_gateway_rest_api.main.execution_arn
}

resource "aws_api_gateway_deployment" "main" {
  rest_api_id = aws_api_gateway_rest_api.main.id

  lifecycle {
    create_before_destroy = true
  }

  depends_on = [module.lambda_endpoints]
}

resource "aws_api_gateway_stage" "main" {
  deployment_id = aws_api_gateway_deployment.main.id
  rest_api_id   = aws_api_gateway_rest_api.main.id
  stage_name    = "production"

  tags = {
    Project = var.project
    Name    = "Main API Gateway Stage"
  }
}

resource "aws_api_gateway_base_path_mapping" "gw_mapping" {
  domain_name = var.api_domain
  api_id      = aws_api_gateway_rest_api.main.id
  stage_name  = aws_api_gateway_stage.main.stage_name
}