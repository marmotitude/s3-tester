variable "profile" {
  type = string
}

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.50.0"
    }
  }
}

provider "aws" {
  profile                     = var.profile
  skip_region_validation      = true
  skip_requesting_account_id  = true
  skip_credentials_validation = true
}
