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
    name               = "TypeIndex"
    hash_key           = "type"
    range_key          = "sk"
    write_capacity     = 0
    read_capacity      = 0
    projection_type    = "ALL"
  }

  global_secondary_index {
    name               = "TypeAndCountryIndex"
    hash_key           = "type_and_country"
    range_key          = "sk"
    write_capacity     = 0
    read_capacity      = 0
    projection_type    = "ALL"
  }

  global_secondary_index {
    name               = "TypeAndCommodityIndex"
    hash_key           = "type_and_commodity"
    range_key          = "sk"
    write_capacity     = 0
    read_capacity      = 0
    projection_type    = "ALL"
  }

  tags = {
    Project = var.project
    Name    = "Main DynamoDB Table"
  }
}