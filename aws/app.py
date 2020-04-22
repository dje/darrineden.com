#!/usr/bin/env python3

from aws_cdk import (core,
                     aws_apigateway as apigw,
                     aws_events as events,
                     aws_dynamodb as dynamodb,
                     aws_lambda as lambda_,
                     aws_logs as logs,
                     aws_ssm as ssm,
                     aws_events_targets as targets)


class DeleteTweetsStack(core.Stack):
    def __init__(self, scope: core.Construct, id: str, **kwargs) -> None:
        super().__init__(scope, id, **kwargs)

        delete_tweets = lambda_.Function(self, "DeleteTweetsHandler",
                                         runtime=lambda_.Runtime.GO_1_X,
                                         code=lambda_.Code.from_asset("functions/build/delete-tweets.zip"),
                                         handler="delete-tweets",
                                         log_retention=logs.RetentionDays.ONE_DAY)

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


class TraceStoreStack(core.Stack):
    def __init__(self, scope: core.Construct, id: str, **kwargs) -> None:
        super().__init__(scope, id, **kwargs)

        spans_table = dynamodb.Table(self, "spans",
                                     partition_key=dynamodb.Attribute(
                                         name="traceId",
                                         type=dynamodb.AttributeType.STRING),
                                     sort_key=dynamodb.Attribute(
                                         name="startTime",
                                         type=dynamodb.AttributeType.STRING),
                                     time_to_live_attribute="ttl",
                                     billing_mode=dynamodb.BillingMode.PAY_PER_REQUEST,
                                     removal_policy=core.RemovalPolicy.DESTROY)

        trace_lambda = lambda_.Function(self, "TraceStoreHandler",
                                        runtime=lambda_.Runtime.GO_1_X,
                                        code=lambda_.Code.from_asset("functions/build/trace-store.zip"),
                                        handler="trace-store",
                                        log_retention=logs.RetentionDays.ONE_DAY)

        trace_lambda.add_environment("TABLE_NAME", spans_table.table_name)

        spans_table.grant(trace_lambda, "dynamodb:PutItem")

        log_group = logs.LogGroup(self, "TraceStoreLogGroup",
                                  removal_policy=core.RemovalPolicy.DESTROY,
                                  retention=logs.RetentionDays.ONE_WEEK)

        api = apigw.RestApi(self, "trace-api",
                            deploy_options=apigw.StageOptions(
                                access_log_destination=apigw.LogGroupLogDestination(log_group),
                                logging_level=apigw.MethodLoggingLevel.INFO),
                            rest_api_name="Trace Store Service",
                            description="This service stores traces.")

        trace = api.root.add_resource("trace")
        trace.add_method("POST", apigw.LambdaIntegration(trace_lambda))


app = core.App()

DeleteTweetsStack(app, "DeleteTweets")
TraceStoreStack(app, "TraceStore")

app.synth()
