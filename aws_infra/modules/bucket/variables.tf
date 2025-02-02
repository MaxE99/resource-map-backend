variable "bucket_name" {
  type        = string
  description = "The name of the S3 bucket to be created."
}

variable "cloudfront_args" {
  type        = map(string)
  description = "A map containing information to create a Cloudfront distribution."
  default = {
    zone_id             = ""
    domain              = ""
    acm_certificate_arn = ""
  }
}

variable "is_media" {
  type        = bool
  default     = false
  description = "Set to true if the S3 bucket is used for media files."
}

variable "tags" {
  type        = map(string)
  description = "A map of tags to apply to all resources."
}