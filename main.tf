provider "aws" {
  region = "ap-northeast-1"
}

# // Terraform Cloudの場合は以下不要
terraform {
  required_version = ">= 1.5.3"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.11.0"
    }
  }
  backend "s3" {
    bucket = "infrastructure-lesson-bucket"
    key    = "dev/terraform.tfstate"
    region = "ap-northeast-1"
  }
}
