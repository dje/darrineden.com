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

output "cfdist" {
  value = aws_cloudfront_distribution.dist.id
}
