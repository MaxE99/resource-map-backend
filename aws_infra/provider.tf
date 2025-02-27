terraform {
  required_version = "1.11.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.50.0"
    }
  }

  backend "s3" {
    bucket  = "ebird-terraform-state-bucket"
    key     = "commodity-project-terraform.tfstate"
    region  = "us-east-2"
    encrypt = true
  }
}

provider "aws" {
  region = "us-east-1"
}