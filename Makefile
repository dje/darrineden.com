build:
	mkdir -p functions
	go build -o functions/hello-lambda ./...
