output "acm_certificate_arn" {
  description = "The ARN of the ACM certificate created for the specified domain."
  value       = aws_acm_certificate.main.arn
}