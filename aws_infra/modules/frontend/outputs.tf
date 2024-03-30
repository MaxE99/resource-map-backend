output "cloudfront_domain" {
  description = "The cloudfront distribution domain name"
  value = aws_cloudfront_distribution.main.domain_name
}

output "cloudfront_hosted_zone_id" {
  description = "The hosted zone of the cloudfront distribution"
  value = aws_cloudfront_distribution.main.hosted_zone_id
}