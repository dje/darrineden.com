### Build Tasks

build-functions: build/delete-tweets.zip

build/delete-tweets.zip : build/delete-tweets
	cd build && \
	zip delete-tweets.zip delete-tweets

delete-tweets/vendor :
	cd delete-tweets && go mod vendor

build/delete-tweets : build delete-tweets/vendor
	cd delete-tweets && \
	go mod vendor && \
	GOOS=linux go build -o ../build/delete-tweets delete-tweets.go

build :
	mkdir build

.PHONY : clean
clean :
	rm -rf build delete-tweets/vendor
