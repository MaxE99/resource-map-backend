output "dynamodb_arn" {
  description = "The ARN of the DynamoDB instance"
  value       = aws_dynamodb_table.main.arn
}