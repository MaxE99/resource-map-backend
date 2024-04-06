locals {
  stage_name = "prod"
}

data "archive_file" "production_package" {
  type        = "zip"
  source_file = "lambdas/production.py"
  output_path = "lambdas/production.zip"
}

data "archive_file" "reserves_package" {
  type        = "zip"
  source_file = "lambdas/reserves.py"
  output_path = "lambdas/reserves.zip"
}

data "archive_file" "gov_info_package" {
  type        = "zip"
  source_file = "lambdas/gov_info.py"
  output_path = "lambdas/gov_info.zip"
}

data "archive_file" "prices_package" {
  type        = "zip"
  source_file = "lambdas/prices.py"
  output_path = "lambdas/prices.zip"
}

data "archive_file" "balance_package" {
  type        = "zip"
  source_file = "lambdas/balance.py"
  output_path = "lambdas/balance.zip"
}

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

resource "aws_lambda_function" "production_lambda" {
  filename         = "lambdas/production.zip"
  function_name    = "productionLambdaFunction"
  role             = aws_iam_role.lambda_role.arn
  handler          = "production.lambda_handler"
  runtime          = "python3.11"
  timeout          = 30
  source_code_hash = data.archive_file.production_package.output_base64sha256

  tags = {
    Project = var.project
    Name    = "Production Lambda Function"
  }
}

resource "aws_lambda_function" "reserves_lambda" {
  filename         = "lambdas/reserves.zip"
  function_name    = "reservesLambdaFunction"
  role             = aws_iam_role.lambda_role.arn
  handler          = "reserves.lambda_handler"
  runtime          = "python3.11"
  timeout          = 30
  source_code_hash = data.archive_file.reserves_package.output_base64sha256

  tags = {
    Project = var.project
    Name    = "Reserves Lambda Function"
  }
}

resource "aws_lambda_function" "gov_info_lambda" {
  filename         = "lambdas/gov_info.zip"
  function_name    = "govInfoLambdaFunction"
  role             = aws_iam_role.lambda_role.arn
  handler          = "gov_info.lambda_handler"
  runtime          = "python3.11"
  timeout          = 30
  source_code_hash = data.archive_file.gov_info_package.output_base64sha256

  tags = {
    Project = var.project
    Name    = "Govinfo Lambda Function"
  }
}

resource "aws_lambda_function" "prices_lambda" {
  filename         = "lambdas/prices.zip"
  function_name    = "pricesLambdaFunction"
  role             = aws_iam_role.lambda_role.arn
  handler          = "prices.lambda_handler"
  runtime          = "python3.11"
  timeout          = 30
  source_code_hash = data.archive_file.prices_package.output_base64sha256

  tags = {
    Project = var.project
    Name    = "Prices Lambda Function"
  }
}

resource "aws_lambda_function" "balance_lambda" {
  filename         = "lambdas/balance.zip"
  function_name    = "balanceLambdaFunction"
  role             = aws_iam_role.lambda_role.arn
  handler          = "balance.lambda_handler"
  runtime          = "python3.11"
  timeout          = 30
  source_code_hash = data.archive_file.balance_package.output_base64sha256

  tags = {
    Project = var.project
    Name    = "Balance Lambda Function"
  }
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
    cloudfront_default_certificate = true
  }

  price_class = "PriceClass_100"

  tags = {
    Project = var.project
    Name    = "APIGateway Cloudfront Distribution"
  }
}

resource "aws_lambda_permission" "production_lambda" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.production_lambda.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.main.execution_arn}/*/*/*"
}

resource "aws_lambda_permission" "reserves_lambda" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.reserves_lambda.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.main.execution_arn}/*/*/*"
}

resource "aws_lambda_permission" "govinfo_lambda" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.gov_info_lambda.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.main.execution_arn}/*/*/*"
}

resource "aws_lambda_permission" "prices_lambda" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.prices_lambda.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.main.execution_arn}/*/*/*"
}

resource "aws_lambda_permission" "balance_lambda" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.balance_lambda.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.main.execution_arn}/*/*/*"
}

resource "aws_api_gateway_resource" "production" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  parent_id   = aws_api_gateway_rest_api.main.root_resource_id
  path_part   = "production"
}

resource "aws_api_gateway_method" "production" {
  rest_api_id   = aws_api_gateway_rest_api.main.id
  resource_id   = aws_api_gateway_resource.production.id
  http_method   = "GET"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "production" {
  rest_api_id             = aws_api_gateway_rest_api.main.id
  resource_id             = aws_api_gateway_resource.production.id
  http_method             = aws_api_gateway_method.production.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.production_lambda.invoke_arn
}

resource "aws_api_gateway_method_response" "production" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  resource_id = aws_api_gateway_resource.production.id
  http_method = aws_api_gateway_method.production.http_method
  status_code = "200"

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = true,
    "method.response.header.Access-Control-Allow-Methods" = true,
    "method.response.header.Access-Control-Allow-Origin"  = true
  }
}

resource "aws_api_gateway_integration_response" "production" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  resource_id = aws_api_gateway_resource.production.id
  http_method = aws_api_gateway_method.production.http_method
  status_code = aws_api_gateway_method_response.production.status_code

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'",
    "method.response.header.Access-Control-Allow-Methods" = "'GET,OPTIONS,POST,PUT'",
    "method.response.header.Access-Control-Allow-Origin"  = "'*'"
  }

  depends_on = [
    aws_api_gateway_method.production,
    aws_api_gateway_integration.production
  ]
}

resource "aws_api_gateway_method" "production_options" {
  rest_api_id   = aws_api_gateway_rest_api.main.id
  resource_id   = aws_api_gateway_resource.production.id
  http_method   = "OPTIONS"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "production_options" {
  rest_api_id             = aws_api_gateway_rest_api.main.id
  resource_id             = aws_api_gateway_resource.production.id
  http_method             = aws_api_gateway_method.production_options.http_method
  integration_http_method = "POST"
  type                    = "MOCK"
  request_templates = {
    "application/json" = "{\"statusCode\": 200}"
  }
}

resource "aws_api_gateway_method_response" "production_options" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  resource_id = aws_api_gateway_resource.production.id
  http_method = aws_api_gateway_method.production_options.http_method
  status_code = "200"

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = true,
    "method.response.header.Access-Control-Allow-Methods" = true,
    "method.response.header.Access-Control-Allow-Origin"  = true
  }
}

resource "aws_api_gateway_integration_response" "production_options" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  resource_id = aws_api_gateway_resource.production.id
  http_method = aws_api_gateway_method.production_options.http_method
  status_code = aws_api_gateway_method_response.production_options.status_code

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'",
    "method.response.header.Access-Control-Allow-Methods" = "'GET,OPTIONS,POST,PUT'",
    "method.response.header.Access-Control-Allow-Origin"  = "'*'"
  }

  depends_on = [
    aws_api_gateway_method.production_options,
    aws_api_gateway_integration.production_options,
  ]
}

resource "aws_api_gateway_resource" "reserves" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  parent_id   = aws_api_gateway_rest_api.main.root_resource_id
  path_part   = "reserves"
}

resource "aws_api_gateway_method" "reserves" {
  rest_api_id   = aws_api_gateway_rest_api.main.id
  resource_id   = aws_api_gateway_resource.reserves.id
  http_method   = "GET"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "reserves" {
  rest_api_id             = aws_api_gateway_rest_api.main.id
  resource_id             = aws_api_gateway_resource.reserves.id
  http_method             = aws_api_gateway_method.reserves.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.reserves_lambda.invoke_arn
}

resource "aws_api_gateway_method_response" "reserves" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  resource_id = aws_api_gateway_resource.reserves.id
  http_method = aws_api_gateway_method.reserves.http_method
  status_code = "200"

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = true,
    "method.response.header.Access-Control-Allow-Methods" = true,
    "method.response.header.Access-Control-Allow-Origin"  = true
  }
}

resource "aws_api_gateway_integration_response" "reserves" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  resource_id = aws_api_gateway_resource.reserves.id
  http_method = aws_api_gateway_method.reserves.http_method
  status_code = aws_api_gateway_method_response.reserves.status_code

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'",
    "method.response.header.Access-Control-Allow-Methods" = "'GET,OPTIONS,POST,PUT'",
    "method.response.header.Access-Control-Allow-Origin"  = "'*'"
  }

  depends_on = [
    aws_api_gateway_method.reserves,
    aws_api_gateway_integration.reserves
  ]
}

resource "aws_api_gateway_method" "reserves_options" {
  rest_api_id   = aws_api_gateway_rest_api.main.id
  resource_id   = aws_api_gateway_resource.reserves.id
  http_method   = "OPTIONS"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "reserves_options" {
  rest_api_id             = aws_api_gateway_rest_api.main.id
  resource_id             = aws_api_gateway_resource.reserves.id
  http_method             = aws_api_gateway_method.reserves_options.http_method
  integration_http_method = "POST"
  type                    = "MOCK"
  request_templates = {
    "application/json" = "{\"statusCode\": 200}"
  }
}

resource "aws_api_gateway_method_response" "reserves_options" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  resource_id = aws_api_gateway_resource.reserves.id
  http_method = aws_api_gateway_method.reserves_options.http_method
  status_code = "200"

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = true,
    "method.response.header.Access-Control-Allow-Methods" = true,
    "method.response.header.Access-Control-Allow-Origin"  = true
  }
}

resource "aws_api_gateway_integration_response" "reserves_options" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  resource_id = aws_api_gateway_resource.reserves.id
  http_method = aws_api_gateway_method.reserves_options.http_method
  status_code = aws_api_gateway_method_response.reserves_options.status_code

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'",
    "method.response.header.Access-Control-Allow-Methods" = "'GET,OPTIONS,POST,PUT'",
    "method.response.header.Access-Control-Allow-Origin"  = "'*'"
  }

  depends_on = [
    aws_api_gateway_method.reserves_options,
    aws_api_gateway_integration.reserves_options,
  ]
}

resource "aws_api_gateway_resource" "gov_info" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  parent_id   = aws_api_gateway_rest_api.main.root_resource_id
  path_part   = "gov_info"
}

resource "aws_api_gateway_method" "gov_info" {
  rest_api_id   = aws_api_gateway_rest_api.main.id
  resource_id   = aws_api_gateway_resource.gov_info.id
  http_method   = "GET"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "gov_info" {
  rest_api_id             = aws_api_gateway_rest_api.main.id
  resource_id             = aws_api_gateway_resource.gov_info.id
  http_method             = aws_api_gateway_method.gov_info.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.gov_info_lambda.invoke_arn
}

resource "aws_api_gateway_method_response" "gov_info" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  resource_id = aws_api_gateway_resource.gov_info.id
  http_method = aws_api_gateway_method.gov_info.http_method
  status_code = "200"

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = true,
    "method.response.header.Access-Control-Allow-Methods" = true,
    "method.response.header.Access-Control-Allow-Origin"  = true
  }
}

resource "aws_api_gateway_integration_response" "gov_info" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  resource_id = aws_api_gateway_resource.gov_info.id
  http_method = aws_api_gateway_method.gov_info.http_method
  status_code = aws_api_gateway_method_response.gov_info.status_code

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'",
    "method.response.header.Access-Control-Allow-Methods" = "'GET,OPTIONS,POST,PUT'",
    "method.response.header.Access-Control-Allow-Origin"  = "'*'"
  }

  depends_on = [
    aws_api_gateway_method.gov_info,
    aws_api_gateway_integration.gov_info
  ]
}

resource "aws_api_gateway_method" "gov_info_options" {
  rest_api_id   = aws_api_gateway_rest_api.main.id
  resource_id   = aws_api_gateway_resource.gov_info.id
  http_method   = "OPTIONS"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "gov_info_options" {
  rest_api_id             = aws_api_gateway_rest_api.main.id
  resource_id             = aws_api_gateway_resource.gov_info.id
  http_method             = aws_api_gateway_method.gov_info_options.http_method
  integration_http_method = "POST"
  type                    = "MOCK"
  request_templates = {
    "application/json" = "{\"statusCode\": 200}"
  }
}

resource "aws_api_gateway_method_response" "gov_info_options" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  resource_id = aws_api_gateway_resource.gov_info.id
  http_method = aws_api_gateway_method.gov_info_options.http_method
  status_code = "200"

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = true,
    "method.response.header.Access-Control-Allow-Methods" = true,
    "method.response.header.Access-Control-Allow-Origin"  = true
  }
}

resource "aws_api_gateway_integration_response" "gov_info_options" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  resource_id = aws_api_gateway_resource.gov_info.id
  http_method = aws_api_gateway_method.gov_info_options.http_method
  status_code = aws_api_gateway_method_response.gov_info_options.status_code

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'",
    "method.response.header.Access-Control-Allow-Methods" = "'GET,OPTIONS,POST,PUT'",
    "method.response.header.Access-Control-Allow-Origin"  = "'*'"
  }

  depends_on = [
    aws_api_gateway_method.gov_info_options,
    aws_api_gateway_integration.gov_info_options,
  ]
}

resource "aws_api_gateway_resource" "prices" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  parent_id   = aws_api_gateway_rest_api.main.root_resource_id
  path_part   = "prices"
}

resource "aws_api_gateway_method" "prices" {
  rest_api_id   = aws_api_gateway_rest_api.main.id
  resource_id   = aws_api_gateway_resource.prices.id
  http_method   = "GET"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "prices" {
  rest_api_id             = aws_api_gateway_rest_api.main.id
  resource_id             = aws_api_gateway_resource.prices.id
  http_method             = aws_api_gateway_method.prices.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.prices_lambda.invoke_arn
}

resource "aws_api_gateway_method_response" "prices" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  resource_id = aws_api_gateway_resource.prices.id
  http_method = aws_api_gateway_method.prices.http_method
  status_code = "200"

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = true,
    "method.response.header.Access-Control-Allow-Methods" = true,
    "method.response.header.Access-Control-Allow-Origin"  = true
  }
}

resource "aws_api_gateway_integration_response" "prices" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  resource_id = aws_api_gateway_resource.prices.id
  http_method = aws_api_gateway_method.prices.http_method
  status_code = aws_api_gateway_method_response.prices.status_code

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'",
    "method.response.header.Access-Control-Allow-Methods" = "'GET,OPTIONS,POST,PUT'",
    "method.response.header.Access-Control-Allow-Origin"  = "'*'"
  }

  depends_on = [
    aws_api_gateway_method.prices,
    aws_api_gateway_integration.prices
  ]
}

resource "aws_api_gateway_method" "prices_options" {
  rest_api_id   = aws_api_gateway_rest_api.main.id
  resource_id   = aws_api_gateway_resource.prices.id
  http_method   = "OPTIONS"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "prices_options" {
  rest_api_id             = aws_api_gateway_rest_api.main.id
  resource_id             = aws_api_gateway_resource.prices.id
  http_method             = aws_api_gateway_method.prices_options.http_method
  integration_http_method = "POST"
  type                    = "MOCK"
  request_templates = {
    "application/json" = "{\"statusCode\": 200}"
  }
}

resource "aws_api_gateway_method_response" "prices_options" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  resource_id = aws_api_gateway_resource.prices.id
  http_method = aws_api_gateway_method.prices_options.http_method
  status_code = "200"

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = true,
    "method.response.header.Access-Control-Allow-Methods" = true,
    "method.response.header.Access-Control-Allow-Origin"  = true
  }
}

resource "aws_api_gateway_integration_response" "prices_options" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  resource_id = aws_api_gateway_resource.prices.id
  http_method = aws_api_gateway_method.prices_options.http_method
  status_code = aws_api_gateway_method_response.prices_options.status_code

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'",
    "method.response.header.Access-Control-Allow-Methods" = "'GET,OPTIONS,POST,PUT'",
    "method.response.header.Access-Control-Allow-Origin"  = "'*'"
  }

  depends_on = [
    aws_api_gateway_method.prices_options,
    aws_api_gateway_integration.prices_options,
  ]
}

resource "aws_api_gateway_resource" "balance" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  parent_id   = aws_api_gateway_rest_api.main.root_resource_id
  path_part   = "balance"
}

resource "aws_api_gateway_method" "balance" {
  rest_api_id   = aws_api_gateway_rest_api.main.id
  resource_id   = aws_api_gateway_resource.balance.id
  http_method   = "GET"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "balance" {
  rest_api_id             = aws_api_gateway_rest_api.main.id
  resource_id             = aws_api_gateway_resource.balance.id
  http_method             = aws_api_gateway_method.balance.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.balance_lambda.invoke_arn
}

resource "aws_api_gateway_method_response" "balance" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  resource_id = aws_api_gateway_resource.balance.id
  http_method = aws_api_gateway_method.balance.http_method
  status_code = "200"

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = true,
    "method.response.header.Access-Control-Allow-Methods" = true,
    "method.response.header.Access-Control-Allow-Origin"  = true
  }
}

resource "aws_api_gateway_integration_response" "balance" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  resource_id = aws_api_gateway_resource.balance.id
  http_method = aws_api_gateway_method.balance.http_method
  status_code = aws_api_gateway_method_response.balance.status_code

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'",
    "method.response.header.Access-Control-Allow-Methods" = "'GET,OPTIONS,POST,PUT'",
    "method.response.header.Access-Control-Allow-Origin"  = "'*'"
  }

  depends_on = [
    aws_api_gateway_method.balance,
    aws_api_gateway_integration.balance
  ]
}

resource "aws_api_gateway_method" "balance_options" {
  rest_api_id   = aws_api_gateway_rest_api.main.id
  resource_id   = aws_api_gateway_resource.balance.id
  http_method   = "OPTIONS"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "balance_options" {
  rest_api_id             = aws_api_gateway_rest_api.main.id
  resource_id             = aws_api_gateway_resource.balance.id
  http_method             = aws_api_gateway_method.balance_options.http_method
  integration_http_method = "POST"
  type                    = "MOCK"
  request_templates = {
    "application/json" = "{\"statusCode\": 200}"
  }
}

resource "aws_api_gateway_method_response" "balance_options" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  resource_id = aws_api_gateway_resource.balance.id
  http_method = aws_api_gateway_method.balance_options.http_method
  status_code = "200"

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = true,
    "method.response.header.Access-Control-Allow-Methods" = true,
    "method.response.header.Access-Control-Allow-Origin"  = true
  }
}

resource "aws_api_gateway_integration_response" "balance_options" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  resource_id = aws_api_gateway_resource.balance.id
  http_method = aws_api_gateway_method.balance_options.http_method
  status_code = aws_api_gateway_method_response.balance_options.status_code

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'",
    "method.response.header.Access-Control-Allow-Methods" = "'GET,OPTIONS,POST,PUT'",
    "method.response.header.Access-Control-Allow-Origin"  = "'*'"
  }

  depends_on = [
    aws_api_gateway_method.balance_options,
    aws_api_gateway_integration.balance_options,
  ]
}

resource "aws_api_gateway_deployment" "main" {
  rest_api_id = aws_api_gateway_rest_api.main.id

  lifecycle {
    create_before_destroy = true
  }
  depends_on = [aws_api_gateway_method.production, aws_api_gateway_integration.production, aws_api_gateway_method.reserves, aws_api_gateway_integration.reserves, aws_api_gateway_method.gov_info, aws_api_gateway_integration.gov_info, aws_api_gateway_method.prices, aws_api_gateway_integration.prices, aws_api_gateway_method.balance, aws_api_gateway_integration.balance]
}

resource "aws_api_gateway_stage" "main" {
  deployment_id = aws_api_gateway_deployment.main.id
  rest_api_id   = aws_api_gateway_rest_api.main.id
  stage_name    = local.stage_name

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