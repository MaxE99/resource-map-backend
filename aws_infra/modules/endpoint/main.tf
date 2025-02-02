# ========================================================================================================================
# Lambda
# ========================================================================================================================

data "archive_file" "main" {
  type        = "zip"
  source_file = "lambdas/${var.path}.py"
  output_path = "lambdas/${var.path}.zip"
}

resource "aws_lambda_function" "main" {
  filename         = "lambdas/${var.path}.zip"
  function_name    = "${var.path}LambdaFunction"
  role             = var.dynamodb_access_role
  handler          = "${var.path}.lambda_handler"
  runtime          = "python3.11"
  timeout          = 30
  source_code_hash = data.archive_file.main.output_base64sha256

  tags = var.tags
}

resource "aws_lambda_permission" "main" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.main.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${var.api_gateway_details.execution_arn}/*/*/*"
}

# ========================================================================================================================
# API Gateway
# ========================================================================================================================

resource "aws_api_gateway_resource" "main" {
  rest_api_id = var.api_gateway_details.id
  parent_id   = var.api_gateway_details.root_resource_id
  path_part   = var.path
}

resource "aws_api_gateway_method" "main" {
  rest_api_id   = var.api_gateway_details.id
  resource_id   = aws_api_gateway_resource.main.id
  http_method   = "GET"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "main" {
  rest_api_id             = var.api_gateway_details.id
  resource_id             = aws_api_gateway_resource.main.id
  http_method             = aws_api_gateway_method.main.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.main.invoke_arn
}

resource "aws_api_gateway_method_response" "main" {
  rest_api_id = var.api_gateway_details.id
  resource_id = aws_api_gateway_resource.main.id
  http_method = aws_api_gateway_method.main.http_method
  status_code = "200"

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = true,
    "method.response.header.Access-Control-Allow-Methods" = true,
    "method.response.header.Access-Control-Allow-Origin"  = true
  }
}

resource "aws_api_gateway_integration_response" "main" {
  rest_api_id = var.api_gateway_details.id
  resource_id = aws_api_gateway_resource.main.id
  http_method = aws_api_gateway_method.main.http_method
  status_code = aws_api_gateway_method_response.main.status_code

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'",
    "method.response.header.Access-Control-Allow-Methods" = "'GET,OPTIONS'",
    "method.response.header.Access-Control-Allow-Origin"  = "'https://${var.domain}'"
  }

  depends_on = [
    aws_api_gateway_method.main,
    aws_api_gateway_integration.main
  ]
}

resource "aws_api_gateway_method" "main_options" {
  rest_api_id   = var.api_gateway_details.id
  resource_id   = aws_api_gateway_resource.main.id
  http_method   = "OPTIONS"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "main_options" {
  rest_api_id = var.api_gateway_details.id
  resource_id = aws_api_gateway_resource.main.id
  http_method = aws_api_gateway_method.main_options.http_method
  type        = "MOCK"
  request_templates = {
    "application/json" = "{\"statusCode\": 200}"
  }
}

resource "aws_api_gateway_method_response" "main_options" {
  rest_api_id = var.api_gateway_details.id
  resource_id = aws_api_gateway_resource.main.id
  http_method = aws_api_gateway_method.main_options.http_method
  status_code = "200"

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = true,
    "method.response.header.Access-Control-Allow-Methods" = true,
    "method.response.header.Access-Control-Allow-Origin"  = true
  }
}

resource "aws_api_gateway_integration_response" "main_options" {
  rest_api_id = var.api_gateway_details.id
  resource_id = aws_api_gateway_resource.main.id
  http_method = aws_api_gateway_method.main_options.http_method
  status_code = aws_api_gateway_method_response.main_options.status_code

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'",
    "method.response.header.Access-Control-Allow-Methods" = "'GET,OPTIONS'",
    "method.response.header.Access-Control-Allow-Origin"  = "'https://${var.domain}'"
  }

  depends_on = [
    aws_api_gateway_method.main_options,
    aws_api_gateway_integration.main_options,
  ]
}