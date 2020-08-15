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
  region = "us-west-2"
}

provider "aws" {
  region = "us-east-1"
  alias  = "east"
}

resource "aws_route53_zone" "zone" {
  name = "darrineden.com"
}

resource "aws_route53_record" "netlify_record" {
  zone_id = aws_route53_zone.zone.zone_id
  name    = "darrineden.com"
  type    = "A"
  ttl     = "300"
  records = ["104.198.14.52"]
}

resource "aws_route53_record" "test_record_ipv4" {
  zone_id = aws_route53_zone.zone.zone_id
  name    = "test.darrineden.com"
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.dist.domain_name
    zone_id                = aws_cloudfront_distribution.dist.hosted_zone_id
    evaluate_target_health = true
  }
}

resource "aws_route53_record" "test_record_ipv6" {
  zone_id = aws_route53_zone.zone.zone_id
  name    = "test.darrineden.com"
  type    = "AAAA"

  alias {
    name                   = aws_cloudfront_distribution.dist.domain_name
    zone_id                = aws_cloudfront_distribution.dist.hosted_zone_id
    evaluate_target_health = true
  }
}

resource "aws_acm_certificate" "cert" {
  provider          = aws.east
  domain_name       = "darrineden.com"
  validation_method = "DNS"

  subject_alternative_names = ["*.darrineden.com"]

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route53_record" "record" {
  for_each = {
    for dvo in aws_acm_certificate.cert.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = aws_route53_zone.zone.zone_id
}

resource "aws_acm_certificate_validation" "validation" {
  provider        = aws.east
  certificate_arn = aws_acm_certificate.cert.arn

  validation_record_fqdns = [for record in aws_route53_record.record : record.fqdn]
}

resource "aws_s3_bucket" "site" {
  acl    = "public-read"
  bucket = "darrineden.com"

  website {
    index_document = "index.html"
  }
}

locals {
  s3_origin_id = "darrinedenS3Origin"
}

resource "aws_cloudfront_distribution" "dist" {
  origin {
    domain_name = aws_s3_bucket.site.bucket_regional_domain_name
    origin_id   = local.s3_origin_id
  }

  enabled             = true
  is_ipv6_enabled     = true
  default_root_object = "index.html"

  aliases = ["darrineden.com", "test.darrineden.com"]

  default_cache_behavior {
    allowed_methods  = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = local.s3_origin_id

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "allow-all"
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    acm_certificate_arn = aws_acm_certificate_validation.validation.certificate_arn
    ssl_support_method  = "sni-only"
  }
}
