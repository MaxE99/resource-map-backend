output "frontend_acm_certificate_arn" {
  description = "The ARN of the acm certificate of the frontend domain"
  value       = aws_acm_certificate.main.arn
}

output "backend_acm_certificate_arn" {
  description = "The ARN of the acm certificate of the backend domain"
  value       = aws_acm_certificate.api.arn
}