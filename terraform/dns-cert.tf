provider "aws" {
  region = "us-east-1"
  alias  = "east"
}

resource "aws_route53_zone" "zone" {
  name = "darrineden.com"
}

resource "aws_route53_record" "record_ipv4" {
  zone_id = aws_route53_zone.zone.zone_id
  name    = "darrineden.com"
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.dist.domain_name
    zone_id                = aws_cloudfront_distribution.dist.hosted_zone_id
    evaluate_target_health = true
  }
}

resource "aws_route53_record" "record_ipv6" {
  zone_id = aws_route53_zone.zone.zone_id
  name    = "darrineden.com"
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
