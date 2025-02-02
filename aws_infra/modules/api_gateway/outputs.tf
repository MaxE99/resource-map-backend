output "api_gateway_details" {
  value = {
    id               = aws_api_gateway_rest_api.main.id
    root_resource_id = aws_api_gateway_rest_api.main.root_resource_id
    execution_arn    = aws_api_gateway_rest_api.main.execution_arn
  }
  description = "The details of the API Gateway, including its ID, root resource ID, and execution ARN."
}