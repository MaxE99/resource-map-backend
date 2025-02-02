# ========================================================================================================================
# API Gateway
# ========================================================================================================================

resource "aws_api_gateway_rest_api" "main" {
  name = "${var.project}-api-gateway"

  endpoint_configuration {
    types = ["REGIONAL"]
  }

  tags = var.tags
}

resource "aws_api_gateway_deployment" "main" {
  rest_api_id = aws_api_gateway_rest_api.main.id

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_api_gateway_stage" "main" {
  deployment_id = aws_api_gateway_deployment.main.id
  rest_api_id   = aws_api_gateway_rest_api.main.id
  stage_name    = "production"
  tags          = var.tags
}

resource "aws_api_gateway_base_path_mapping" "gw_mapping" {
  domain_name = var.domain
  api_id      = aws_api_gateway_rest_api.main.id
  stage_name  = aws_api_gateway_stage.main.stage_name
}