#!/usr/bin/env python3

from aws_cdk import (core,
                     aws_events as events,
                     aws_lambda as lambda_,
                     aws_ssm as ssm,
                     aws_events_targets as targets)


class DarrinEdenStack(core.Stack):
    def __init__(self, scope: core.Construct, id: str, **kwargs) -> None:
        super().__init__(scope, id, **kwargs)

        delete_tweets = lambda_.Function(self, "DeleteTweetsHandler",
                                         runtime=lambda_.Runtime.GO_1_X,
                                         code=lambda_.Code.from_asset("functions/build/delete-tweets.zip"),
                                         handler="delete-tweets")

        [ssm.StringParameter.from_secure_string_parameter_attributes(
            self, f"Twitter{i}Value",
            parameter_name=f"/DeleteTweets/Twitter{i}",
            version=1).grant_read(delete_tweets)
         for i in ["ClientId",
                   "ClientSecret",
                   "AccessToken",
                   "AccessSecret"]
         ]

        events.Rule(self, "DeleteTweetsHourlyEvent",
                    schedule=events.Schedule.cron(minute="0"),
                    targets=[targets.LambdaFunction(delete_tweets)])


app = core.App()
DarrinEdenStack(app, "DarrinEdenStack")
app.synth()
