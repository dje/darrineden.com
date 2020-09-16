### Build Tasks

build-functions: clean build/delete-tweets.zip build/carbon.zip

build/carbon.zip : build/carbon
	cd build && \
	zip carbon.zip carbon

build/delete-tweets.zip : build/delete-tweets
	cd build && \
	zip delete-tweets.zip delete-tweets

build/delete-tweets : build
	cd delete-tweets && \
	go mod vendor && \
	GOOS=linux go build -o ../build/delete-tweets delete-tweets.go

build/carbon : build
	cd carbon && \
	go mod vendor && \
	GOOS=linux go build -o ../build/carbon carbon.go

build :
	mkdir build

.PHONY : clean
clean :
	rm -rf build carbon/vendor delete-tweets/vendor
