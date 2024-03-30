output "acm_certificate_arn" {
  description = "The ARN of the acm certificate of the domain"
  value       = aws_acm_certificate.main.arn
}