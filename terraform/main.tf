terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }

  backend "s3" {
    bucket  = "darrineden.com-terraform"
    key     = "terraform-state"
    region  = "us-west-2"
    encrypt = true
  }
}

provider "aws" {
  region = "us-west-2"
}
