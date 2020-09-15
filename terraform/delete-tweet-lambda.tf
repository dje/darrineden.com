variable "twitter_client_id" {
  type = string
}

variable "twitter_client_secret" {
  type = string
}

variable "twitter_access_token" {
  type = string
}

variable "twitter_access_secret" {
  type = string
}

variable "honeycomb_api_key" {
  type = string
}

resource "aws_ssm_parameter" "twitter_client_id" {
  name        = "/DeleteTweets/TwitterClientId"
  description = "Twitter Client ID"
  type        = "SecureString"
  value       = var.twitter_client_id
}

resource "aws_ssm_parameter" "twitter_client_secret" {
  name        = "/DeleteTweets/TwitterClientSecret"
  description = "Twitter Client Secret"
  type        = "SecureString"
  value       = var.twitter_client_secret
}

resource "aws_ssm_parameter" "twitter_access_token" {
  name        = "/DeleteTweets/TwitterAccessToken"
  description = "Twitter Access Token"
  type        = "SecureString"
  value       = var.twitter_access_token
}

resource "aws_ssm_parameter" "twitter_access_secret" {
  name        = "/DeleteTweets/TwitterAccessSecret"
  description = "Twitter Access Secret"
  type        = "SecureString"
  value       = var.twitter_access_secret
}

resource "aws_ssm_parameter" "honeycomb_api_key" {
  name        = "/Honeycomb/APIKey"
  description = "Honeycomb API Key"
  type        = "SecureString"
  value       = var.honeycomb_api_key
}

data "aws_iam_policy_document" "assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "iam_for_lambda" {
  name               = "iam_for_lambda"
  assume_role_policy = data.aws_iam_policy_document.assume_role_policy.json
}

resource "aws_lambda_function" "delete_tweets_lambda" {
  filename      = "../aws/functions/build/delete-tweets.zip"
  function_name = "delete-tweets"
  role          = aws_iam_role.iam_for_lambda.arn
  handler       = "delete-tweets"

  source_code_hash = filebase64sha256("../aws/functions/build/delete-tweets.zip")

  runtime = "go1.x"

  depends_on = [
    aws_iam_role_policy_attachment.lambda_logs,
    aws_cloudwatch_log_group.delete_tweets_log_group,
  ]
}

resource "aws_cloudwatch_log_group" "delete_tweets_log_group" {
  name              = "/aws/lambda/delete-tweets"
  retention_in_days = 14
}

resource "aws_iam_policy" "lambda_logging" {
  name        = "lambda_logging"
  path        = "/"
  description = "IAM policy for logging from a lambda"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Resource": "arn:aws:logs:*:*:*",
      "Effect": "Allow"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "lambda_logs" {
  role       = aws_iam_role.iam_for_lambda.name
  policy_arn = aws_iam_policy.lambda_logging.arn
}

resource "aws_cloudwatch_event_rule" "every_hour" {
  name                = "hourly-event"
  description         = "Fires every hour"
  schedule_expression = "rate(1 hour)"
}

resource "aws_cloudwatch_event_target" "delete_tweets_lambda_every_hour" {
  rule      = aws_cloudwatch_event_rule.every_hour.name
  target_id = "delete_tweets_lambda"
  arn       = aws_lambda_function.delete_tweets_lambda.arn
}

resource "aws_lambda_permission" "allow_cloudwatch_to_call_delete_tweets_lambda" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.delete_tweets_lambda.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.every_hour.arn
}

data "aws_iam_policy_document" "ssm_policy_document" {
  statement {
    actions = [
      "ssm:GetParameter",
      "ssm:GetParameters",
      "ssm:GetParametersByPath",
    ]

    resources = [
      aws_ssm_parameter.twitter_client_id.arn,
      aws_ssm_parameter.twitter_client_secret.arn,
      aws_ssm_parameter.twitter_access_token.arn,
      aws_ssm_parameter.twitter_access_secret.arn,
      aws_ssm_parameter.honeycomb_api_key.arn,
    ]
  }
}

resource "aws_iam_policy" "ssm_policy" {
  policy = data.aws_iam_policy_document.ssm_policy_document.json
}

resource "aws_iam_role_policy_attachment" "ssm_policy_attachment" {
  role       = aws_iam_role.iam_for_lambda.name
  policy_arn = aws_iam_policy.ssm_policy.arn
}
