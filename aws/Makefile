.PHONY : build
build :
	cd functions && $(MAKE) clean build-functions

.PHONY : dev
dev : .env
	source .env/bin/activate && \
	pip install pip install \
		aws-cdk.aws-apigatewayv2 \
		aws-cdk.aws-events-targets \
		aws-cdk.aws-dynamodb \
		aws-cdk.aws-iam \
		aws-cdk.aws-lambda \
		aws-cdk.aws-logs \
		aws-cdk.aws-route53 \
		aws-cdk.aws-ssm

.env :
	virtualenv .env

.PHONY : clean
clean :
	rm -rf .env
	cd functions && $(MAKE) clean

.PHONY : deploy
deploy : deploy-delete-tweets deploy-trace-store

.PHONY : deploy-delete-tweets
deploy-delete-tweets : build
	cdk deploy "DeleteTweets" --require-approval=never

.PHONY : deploy-trace-store
deploy-trace-store : build
	cdk deploy "TraceStore" --require-approval=never
