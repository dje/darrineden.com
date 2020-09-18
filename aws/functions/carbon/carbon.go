package main

import (
	"context"

	"github.com/aws/aws-lambda-go/lambda"
)

func handler(_ context.Context) (int, error) {
	return 0, nil
}

func main() {
	lambda.Start(handler)
}
