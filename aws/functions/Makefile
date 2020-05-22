### Build Tasks

build-functions: build/delete-tweets.zip build/trace-store.zip

build/trace-store.zip : build/trace-store
	cd build && \
	zip trace-store.zip trace-store

build/delete-tweets.zip : build/delete-tweets
	cd build && \
	zip delete-tweets.zip delete-tweets

build/trace-store : build
	cd trace-store && \
	GOOS=linux go build -o ../build/trace-store trace-store.go

build/delete-tweets : build
	cd delete-tweets && \
	GOOS=linux go build -o ../build/delete-tweets delete-tweets.go

build :
	mkdir build

.PHONY : clean
clean :
	rm -rf build

### AWS Command Tasks (Secrets and Certificate)

TWITTER_CLIENT_ID ?= SomeTwitterClientId
TWITTER_CLIENT_SECRET ?= SomeTwitterClientSecret

TWITTER_ACCESS_TOKEN ?= SomeTwitterAccessToken
TWITTER_ACCESS_SECRET ?= SomeTwitterAccessSecret

.PHONY : put-secrets
put-secrets :
	export AWS_PAGER="" && \
	aws ssm put-parameter \
		--name "/DeleteTweets/TwitterClientId" \
		--value "$(TWITTER_CLIENT_ID)" \
		--type "SecureString" \
		--overwrite && \
	aws ssm put-parameter \
		--name "/DeleteTweets/TwitterClientSecret" \
		--value "$(TWITTER_CLIENT_SECRET)" \
		--type "SecureString" \
		--overwrite && \
	aws ssm put-parameter \
		--name "/DeleteTweets/TwitterAccessToken" \
		--value "$(TWITTER_ACCESS_TOKEN)" \
		--type "SecureString" \
		--overwrite && \
	aws ssm put-parameter \
		--name "/DeleteTweets/TwitterAccessSecret" \
		--value "$(TWITTER_ACCESS_SECRET)" \
		--type "SecureString" \
		--overwrite

.PHONY : delete-secrets
delete-secrets :
	export AWS_PAGER="" && \
	aws ssm delete-parameter \
		--name "/DeleteTweets/TwitterClientId" && \
	aws ssm delete-parameter \
		--name "/DeleteTweets/TwitterClientSecret" && \
	aws ssm delete-parameter \
		--name "/DeleteTweets/TwitterAccessToken" && \
	aws ssm delete-parameter \
		--name "/DeleteTweets/TwitterAccessSecret"

.PHONY : request-certificate
request-certificate :
	aws acm request-certificate --domain-name api.darrineden.com \
		--validation-method DNS \
		--options CertificateTransparencyLoggingPreference=DISABLED \
		--idempotency-token someRandomToken
