variable "api_gateway_details" {
  type = map(string)
  default = {
    id               = ""
    root_resource_id = ""
    execution_arn    = ""
  }
  description = "A map containing the details of the API Gateway, including the API ID, root resource ID, and execution ARN."
}

variable "domain" {
  type        = string
  description = "The domain name associated with the API Gateway, used for setting up CORS and other URL-related configurations."
}

variable "dynamodb_access_role" {
  type        = string
  description = "The ARN of the IAM role that grants Lambda functions access to interact with DynamoDB."
}

variable "path" {
  type        = string
  description = "The path that will be appended to the API Gateway's base URL to create a new resource (e.g., 'users', 'orders')."
}

variable "project" {
  type        = string
  description = "The name of the project, typically used as a prefix for naming resources"
}

variable "tags" {
  type        = map(string)
  description = "A map of tags to apply to all resources."
}