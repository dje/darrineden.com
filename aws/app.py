#!/usr/bin/env python3

from aws_cdk import (core,
                     aws_apigateway as apigw,
                     aws_lambda as lambda_,
                     aws_logs as logs,
                     aws_ssm as ssm)


class DarrinEdenStack(core.Stack):
    def __init__(self, scope: core.Construct, id: str, **kwargs) -> None:
        super().__init__(scope, id, **kwargs)

        log_group = logs.LogGroup(self, "DeleteTweetsLogGroup",
                                  removal_policy=core.RemovalPolicy.DESTROY,
                                  retention=logs.RetentionDays.ONE_WEEK
                                  )

        delete_tweets = lambda_.Function(self, "DeleteTweetsHandler",
                                         runtime=lambda_.Runtime.GO_1_X,
                                         code=lambda_.Code.from_asset("functions/build/delete-tweets.zip"),
                                         handler="delete-tweets")

        [ssm.StringParameter.from_secure_string_parameter_attributes(
            self, f"Twitter{i}Value",
            parameter_name=f"/DeleteTweets/Twitter{i}",
            version=1
        ).grant_read(delete_tweets) for i in ["ClientId", "ClientSecret", "AccessToken", "AccessSecret"]]

        api = apigw.RestApi(self, "delete-tweets",
                            deploy_options=apigw.StageOptions(
                                access_log_destination=apigw.LogGroupLogDestination(log_group),
                                logging_level=apigw.MethodLoggingLevel.INFO
                            ),
                            rest_api_name="Delete Tweets",
                            description="This service deletes tweets.")

        api.root.add_method("GET", apigw.LambdaIntegration(delete_tweets))


app = core.App()
DarrinEdenStack(app, "DarrinEdenStack")
app.synth()
