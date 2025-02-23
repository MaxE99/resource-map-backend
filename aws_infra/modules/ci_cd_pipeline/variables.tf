variable "cloudfront_arn" {
  type        = string
  description = "The ARN of the CloudFront distribution to invalidate"
}

variable "github_repository" {
  type        = string
  description = "The GitHub repository associated with the frontend, used for the OIDC assumption"
}

variable "project" {
  type        = string
  description = "The project name used for naming AWS resources"
}

variable "s3_bucket_arn" {
  type        = string
  description = "The ARN of the S3 bucket for storing static files"
}

variable "tags" {
  type        = map(string)
  description = "A map of tags to apply to all resources."
}