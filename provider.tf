provider "aws" {
  profile             = "default"
  region              = "ap-south-1"
  allowed_account_ids = [434605749312]
  default_tags {
    tags = {
      environment = var.env
      managedby   = "terraform"
    }
  }
}
terraform {
  required_version = ">= 0.15.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.29.0"
    }
  }
}
