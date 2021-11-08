resource "aws_appsync_api_key" "test" {
  api_id  = aws_appsync_graphql_api.carbon.id
  expires = "2022-01-01T00:00:00Z"
}

resource "aws_appsync_graphql_api" "carbon" {
  authentication_type = "API_KEY"
  name                = "carbon_api"
  schema              = file("../carbon.graphql")
  xray_enabled        = true
}

resource "aws_iam_role" "carbon_lambda" {
  assume_role_policy = data.aws_iam_policy_document.assume_role_lambda.json
}

resource "aws_lambda_function" "carbon_lambda" {
  filename      = "../aws/functions/build/carbon.zip"
  function_name = "carbon"
  role          = aws_iam_role.carbon_lambda.arn
  handler       = "carbon"

  source_code_hash = filebase64sha256("../aws/functions/build/carbon.zip")

  runtime = "go1.x"

  depends_on = [
    aws_iam_role_policy_attachment.carbon_logs,
    aws_cloudwatch_log_group.carbon_log_group,
  ]
}

resource "aws_cloudwatch_log_group" "carbon_log_group" {
  name              = "/aws/lambda/carbon"
  retention_in_days = 14
}

data "aws_iam_policy_document" "carbon_logging_policy" {
  statement {
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]

    resources = ["arn:aws:logs:*:*:*"]
  }
}

resource "aws_iam_policy" "carbon_logging" {
  path   = "/"
  policy = data.aws_iam_policy_document.carbon_logging_policy.json
}

resource "aws_iam_role_policy_attachment" "carbon_logs" {
  role       = aws_iam_role.carbon_lambda.name
  policy_arn = aws_iam_policy.carbon_logging.arn
}

resource "aws_appsync_datasource" "carbon_lambda" {
  name             = "carbon_lambda_appsync"
  api_id           = aws_appsync_graphql_api.carbon.id
  service_role_arn = aws_iam_role.iam_for_appsync.arn
  type             = "AWS_LAMBDA"

  lambda_config {
    function_arn = aws_lambda_function.carbon_lambda.arn
  }
}

resource "aws_appsync_resolver" "carbon" {
  api_id      = aws_appsync_graphql_api.carbon.id
  field       = "atmosphericCarbonTonsToRemove"
  type        = "Query"
  data_source = aws_appsync_datasource.carbon_lambda.name

  request_template = <<EOF
{
    "version": "2017-02-28",
    "operation": "Invoke",
    "payload": {
        "field": "atmosphericCarbonTonsToRemove",
        "arguments": $utils.toJson($context.arguments)
    }
}
EOF

  response_template = "$util.toJson($ctx.result)"
}

data "aws_iam_policy_document" "assume_role_policy_appsync" {
  statement {
    actions = ["sts:AssumeRole"]
    effect  = "Allow"

    principals {
      type        = "Service"
      identifiers = ["appsync.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "iam_for_appsync" {
  assume_role_policy = data.aws_iam_policy_document.assume_role_policy_appsync.json
}

resource "aws_iam_role_policy" "carbon" {
  role = aws_iam_role.iam_for_appsync.id

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "lambda:InvokeFunction"
      ],
      "Effect": "Allow",
      "Resource": [
        "${aws_lambda_function.carbon_lambda.arn}"
      ]
    }
  ]
}
EOF
}
