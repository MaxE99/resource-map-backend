output "cloudfront_arn" {
  description = "The ARN of the CloudFront distribution associated with the S3 bucket."
  value = aws_cloudfront_distribution.bucket.arn
}

output "s3_bucket_arn" {
  description = "The ARN of the S3 bucket used for storing website files."
  value = aws_s3_bucket.main.arn
}
