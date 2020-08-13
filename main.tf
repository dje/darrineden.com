terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }
}

provider "aws" {
  profile = "default"
  region = "us-west-2"
}

resource "aws_acm_certificate" "cert" {
  domain_name       = "darrineden.com"
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_s3_bucket" "site" {
  acl = "public-read"
  bucket = "darrineden.com"

  website {
    index_document = "index.html"
  }
}
