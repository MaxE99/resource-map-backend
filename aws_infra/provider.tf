provider "aws" {
  region = "us-east-1"
}

terraform {
  backend "s3" {
    bucket  = "ebird-terraform-state-bucket"
    key     = "commodity-project-terraform.tfstate"
    region  = "us-east-2"
    encrypt = true
  }
}