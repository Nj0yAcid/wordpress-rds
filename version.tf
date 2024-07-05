terraform {
  required_providers {
    aws = {
        version = "4.67.0"
        source = "hashicorp/aws"
    }
  }
}

provider "aws" {
  region ="us-east-1"
}