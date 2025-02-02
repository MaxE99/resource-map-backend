output "dynamodb_access_role" {
  description = "The ARN of the IAM role that grants Lambda access to interact with DynamoDB."
  value       = aws_iam_role.lambda_role.arn
}