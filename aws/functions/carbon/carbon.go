package main

import (
	"context"

	"github.com/aws/aws-lambda-go/lambda"
)

func handler(_ context.Context) (float64, error) {
	atmosphericCarbonTonsToRemove := 9e11
	return atmosphericCarbonTonsToRemove, nil
}

func main() {
	lambda.Start(handler)
}
