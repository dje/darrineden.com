#!/usr/bin/env python3

from aws_cdk import (core,
                     aws_apigatewayv2 as apigw,
                     aws_events as events,
                     aws_events_targets as targets,
                     aws_dynamodb as dynamodb,
                     aws_iam as iam,
                     aws_lambda as lambda_,
                     aws_logs as logs,
                     aws_ssm as ssm)


class DeleteTweetsStack(core.Stack):
    def __init__(self, scope: core.Construct, id: str, **kwargs) -> None:
        super().__init__(scope, id, **kwargs)

        delete_tweets = lambda_.Function(self, "DeleteTweetsHandler",
                                         runtime=lambda_.Runtime.GO_1_X,
                                         code=lambda_.Code.from_asset("functions/build/delete-tweets.zip"),
                                         log_retention=logs.RetentionDays.ONE_WEEK,
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

        events.Rule(self, "DeleteTweetsDailyEvent",
                    schedule=events.Schedule.cron(minute="0", hour="0"),
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
                                        log_retention=logs.RetentionDays.ONE_WEEK,
                                        handler="trace-store")

        trace_lambda.add_environment("TABLE_NAME", spans_table.table_name)

        spans_table.grant(trace_lambda, "dynamodb:PutItem")

        log_group = logs.LogGroup(self, "TraceStoreLogGroup",
                                  removal_policy=core.RemovalPolicy.DESTROY,
                                  retention=logs.RetentionDays.ONE_WEEK)

        role = iam.Role(self, "TraceStoreApiGwRole",
                        assumed_by=iam.ServicePrincipal("apigateway.amazonaws.com"))

        trace_lambda.grant_invoke(role)

        trace_api = apigw.CfnApi(self, "TraceStoreApi",
                                 name="Trace Store Service",
                                 protocol_type="HTTP",
                                 cors_configuration=apigw.CfnApi.CorsProperty(
                                     allow_origins=["https://darrineden.com"]
                                 ),
                                 target=trace_lambda.function_arn,
                                 credentials_arn=role.role_arn,
                                 description="A service to store traces.")

        # trace_stage = apigw.CfnStage(self, "TraceStoreStage",
        #                              api_id=core.Fn.ref(trace_api.logical_id),
        #                              stage_name="$default",
        #                              access_log_settings=apigw.CfnStage.AccessLogSettingsProperty(
        #                                  destination_arn=log_group.log_group_arn))

        certificate_arn = ssm.StringParameter.value_for_string_parameter(self, "/TraceStore/CertificateARN")

        domain = apigw.CfnDomainName(self, "DarrinEdenApiDomain",
                                     domain_name="api.darrineden.com",
                                     domain_name_configurations=[
                                         apigw.CfnDomainName.DomainNameConfigurationProperty(
                                             certificate_arn=certificate_arn,
                                             certificate_name="api.darrineden.com")])

        domain_map = apigw.CfnApiMapping(self, "TraceStoreApiMap",
                                         api_id=core.Fn.ref(trace_api.logical_id),
                                         domain_name="api.darrineden.com",
                                         stage="$default")


app = core.App()

DeleteTweetsStack(app, "DeleteTweets")
TraceStoreStack(app, "TraceStore")

app.synth()
