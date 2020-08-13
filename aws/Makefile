.PHONY : build
build :
	cd functions && $(MAKE) clean build-functions

.PHONY : dev
dev : cdk-deps-requirements

.PHONY : cdk-deps-requirements
cdk-deps-requirements : .env
	source .env/bin/activate && \
	pip install -r requirements.txt

.PHONY : cdk-deps-update
cdk-deps-update : .env
	source .env/bin/activate && \
	pip install pip install \
		aws-cdk.aws-apigatewayv2 \
		aws-cdk.aws-events-targets \
		aws-cdk.aws-dynamodb \
		aws-cdk.aws-iam \
		aws-cdk.aws-lambda \
		aws-cdk.aws-logs \
		aws-cdk.aws-route53 \
		aws-cdk.aws-ssm && \
	pip freeze > requirements.txt

.env :
	virtualenv .env

.PHONY : clean
clean :
	rm -rf .env cdk.out cdk.context.json
	cd functions && $(MAKE) clean

.PHONY : deploy
deploy : deploy-delete-tweets deploy-trace-store

.PHONY : deploy-delete-tweets
deploy-delete-tweets : build
	cdk deploy "DeleteTweets" --require-approval=never

.PHONY : deploy-trace-store
deploy-trace-store : build
	cdk deploy "TraceStore" --require-approval=never
