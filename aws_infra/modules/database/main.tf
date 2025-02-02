# ========================================================================================================================
# DynamoDB
# ========================================================================================================================

resource "aws_dynamodb_table" "main" {
  name                        = "Commodities"
  billing_mode                = "PAY_PER_REQUEST"
  hash_key                    = "pk"
  range_key                   = "sk"
  read_capacity               = 0
  write_capacity              = 0
  deletion_protection_enabled = true

  attribute {
    name = "pk"
    type = "S"
  }

  attribute {
    name = "sk"
    type = "N"
  }

  attribute {
    name = "type"
    type = "S"
  }

  attribute {
    name = "type_and_country"
    type = "S"
  }

  attribute {
    name = "type_and_commodity"
    type = "S"
  }

  global_secondary_index {
    name            = "TypeIndex"
    hash_key        = "type"
    range_key       = "sk"
    write_capacity  = 0
    read_capacity   = 0
    projection_type = "ALL"
  }

  global_secondary_index {
    name            = "TypeAndCountryIndex"
    hash_key        = "type_and_country"
    range_key       = "sk"
    write_capacity  = 0
    read_capacity   = 0
    projection_type = "ALL"
  }

  global_secondary_index {
    name            = "TypeAndCommodityIndex"
    hash_key        = "type_and_commodity"
    range_key       = "sk"
    write_capacity  = 0
    read_capacity   = 0
    projection_type = "ALL"
  }

  tags = var.tags
}

# ========================================================================================================================
# IAM Role
# ========================================================================================================================

resource "aws_iam_role" "lambda_role" {
  name = "lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })

  tags = var.tags
}

resource "aws_iam_policy" "dynamodb_lambda_policy" {
  name        = "dynamodb_lambda_policy"
  description = "Allows Lambda to access DynamoDB"
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Action" : [
          "dynamodb:GetItem",
          "dynamodb:Query",
        ],
        "Resource" : [
          aws_dynamodb_table.main.arn,
          "${aws_dynamodb_table.main.arn}/index/*"
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_basic" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
  role       = aws_iam_role.lambda_role.name
}

resource "aws_iam_role_policy_attachment" "lambda_dynamodb" {
  policy_arn = aws_iam_policy.dynamodb_lambda_policy.arn
  role       = aws_iam_role.lambda_role.name
}