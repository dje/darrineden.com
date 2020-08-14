terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }

  backend "s3" {
    bucket = "darrineden.com-terraform"
    key    = "terraform-state"
    region = "us-west-2"
  }
}

provider "aws" {
  profile = "default"
  region = "us-west-2"
}

resource "aws_acm_certificate" "cert" {
  domain_name = "darrineden.com"
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}

data "aws_route53_zone" "zone" {
  name = "darrineden.com"
  private_zone = false
}

resource "aws_route53_record" "record" {
  for_each = {
    for dvo in aws_acm_certificate.cert.domain_validation_options : dvo.domain_name => {
      name = dvo.resource_record_name
      record = dvo.resource_record_value
      type = dvo.resource_record_type
    }
  }

  allow_overwrite = true
  name = each.value.name
  records = [each.value.record]
  ttl = 60
  type = each.value.type
  zone_id = data.aws_route53_zone.zone.zone_id
}

resource "aws_s3_bucket" "site" {
  acl = "public-read"
  bucket = "darrineden.com"

  website {
    index_document = "index.html"
  }
}
