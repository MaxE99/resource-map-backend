variable "domain" {
  type        = string
  description = "The custom domain name that will be used for the API Gateway (e.g., api.example.com)."
}

variable "project" {
  type        = string
  description = "The name of the project, typically used as a prefix for naming resources"
}

variable "tags" {
  type        = map(string)
  description = "A map of tags to apply to all resources."
}