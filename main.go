package main

import (
	"context"
	"log"
	"os"

	"github.com/aws/aws-lambda-go/events"
	"github.com/aws/aws-lambda-go/lambda"
	"github.com/dghubble/go-twitter/twitter"

	"golang.org/x/oauth2/clientcredentials"
)

func handler(_ events.APIGatewayProxyRequest) (events.APIGatewayProxyResponse, error) {
	config := &clientcredentials.Config{
		ClientID:     os.Getenv("TWITTER_CLIENT_ID"),
		ClientSecret: os.Getenv("TWITTER_CLIENT_SECRET"),
		TokenURL:     "https://api.twitter.com/oauth2/token",
	}
	httpClient := config.Client(context.Background())

	client := twitter.NewClient(httpClient)
	homeTimelineParams := &twitter.HomeTimelineParams{}

	tweets, resp, err := client.Timelines.HomeTimeline(homeTimelineParams)
	if err != nil {
		log.Fatal(err)
	}

	return events.APIGatewayProxyResponse{
		StatusCode: resp.StatusCode,
		Body:       tweets[0].FullText,
	}, nil
}

func main() {
	lambda.Start(handler)
}
