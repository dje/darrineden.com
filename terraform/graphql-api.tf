resource "aws_cognito_user_pool" "pool" {
  name = "api"
}

resource "aws_appsync_graphql_api" "carbon" {
  authentication_type = "AMAZON_COGNITO_USER_POOLS"
  name                = aws_cognito_user_pool.pool.name
  schema              = file("../carbon.graphql")

  user_pool_config {
    default_action = "DENY"
    user_pool_id   = aws_cognito_user_pool.pool.id
  }
}
