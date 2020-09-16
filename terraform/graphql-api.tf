resource "aws_appsync_api_key" "test" {
  api_id  = aws_appsync_graphql_api.carbon.id
  expires = "2021-01-01T00:00:00Z"
}

resource "aws_appsync_graphql_api" "carbon" {
  authentication_type = "API_KEY"
  name                = "carbon_api"
  schema              = file("../carbon.graphql")
}

data "aws_iam_policy_document" "assume_role_policy_appsync" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["appsync.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "iam_for_appsync" {
  assume_role_policy = data.aws_iam_policy_document.assume_role_policy_appsync.json
}

resource "aws_lambda_function" "carbon_lambda" {
  filename      = "../aws/functions/build/carbon.zip"
  function_name = "carbon"
  role          = aws_iam_role.iam_for_lambda.arn
  handler       = "carbon"

  source_code_hash = filebase64sha256("../aws/functions/build/carbon.zip")

  runtime = "go1.x"
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
