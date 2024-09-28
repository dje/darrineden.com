resource "aws_s3_bucket" "logs" {
  bucket = "darrineden.com-logs"
}

resource "aws_s3_bucket_versioning" "logs_versioning" {
  bucket = aws_s3_bucket.logs.id
  versioning_configuration {
    status = "Disabled"
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "logs_lifecycle" {
  bucket = aws_s3_bucket.logs.id

  rule {
    id     = "expire-logs"
    status = "Enabled"

    expiration {
      days = 180
    }
  }

  rule {
    id     = "onezone-tier"
    status = "Enabled"

    transition {
      storage_class = "ONEZONE_IA"
      days          = 30
    }
  }
}

resource "aws_s3_bucket_acl" "logs_acl" {
  bucket = aws_s3_bucket.logs.id
  acl    = "log-delivery-write"
}

resource "aws_iam_policy" "cloudfront_logging_policy" {
  name        = "CloudFrontLoggingPolicy"
  description = "Allow CloudFront to write logs"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = "s3:PutObject"
        Resource = "arn:aws:s3:::darrineden.com-logs/*"
      }
    ]
  })
}

resource "aws_iam_role" "cloudfront_logging_role" {
  name = "cloudfront_logging_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "cloudfront.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "cloudfront_logging_policy_attachment" {
  role       = aws_iam_role.cloudfront_logging_role.name
  policy_arn = aws_iam_policy.cloudfront_logging_policy.arn
}
