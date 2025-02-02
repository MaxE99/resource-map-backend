variable "domain" {
  type        = string
  description = "The domain name to create and validate the ACM certificate for."
}

variable "enable_api_gateway_domain" {
  type        = bool
  default     = false
  description = "Whether to create an API Gateway custom domain. Set to true to enable."
}

variable "tags" {
  type        = map(string)
  description = "A map of tags to apply to all resources."
}

variable "zone_id" {
  type        = string
  description = "The Route 53 hosted zone ID where DNS records should be created."
}