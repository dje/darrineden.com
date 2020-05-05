.PHONY : build
build :
	cd functions && $(MAKE) clean build-functions

.PHONY : deploy
deploy : deploy-delete-tweets deploy-trace-store

.PHONY : deploy-delete-tweets
deploy-delete-tweets : build
	cdk deploy "DeleteTweets" --require-approval=never

.PHONY : deploy-trace-store
deploy-trace-store : build
	cdk deploy "TraceStore" --require-approval=never
