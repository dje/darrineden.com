package main

import (
	"context"
	"fmt"
	"log"
	"os"
	"time"

	"github.com/aws/aws-lambda-go/events"
	"github.com/aws/aws-lambda-go/lambda"
	"github.com/dghubble/go-twitter/twitter"
	"github.com/dghubble/oauth1"
)

func handler(_ events.APIGatewayProxyRequest) (events.APIGatewayProxyResponse, error) {
	config := oauth1.NewConfig(
		os.Getenv("TWITTER_CLIENT_ID"),
		os.Getenv("TWITTER_CLIENT_SECRET"),
	)
	token := oauth1.NewToken(
		os.Getenv("TWITTER_ACCESS_TOKEN"),
		os.Getenv("TWITTER_ACCESS_SECRET"),
	)

	httpClient := config.Client(context.Background(), token)
	client := twitter.NewClient(httpClient)

	userTimelineParams := &twitter.UserTimelineParams{}

	tweets, resp, err := client.Timelines.UserTimeline(userTimelineParams)
	if err != nil {
		log.Fatal(err)
	}

	threeDaysAgo := time.Now().AddDate(0, 0, -2)
	destroyed := 0

	for _, tweet := range tweets {
		tweetTime, _ := time.Parse(time.RubyDate, tweet.CreatedAt)
		if tweetTime.Before(threeDaysAgo) {
			if tweet.Retweeted {
				_, _, err := client.Statuses.Unretweet(tweet.ID, &twitter.StatusUnretweetParams{})
				if err != nil {
					log.Print(err)
				}
				destroyed++
			} else {
				_, _, err := client.Statuses.Destroy(tweet.ID, &twitter.StatusDestroyParams{})
				if err != nil {
					log.Print(err)
				}
				destroyed++
			}
		}

	}

	return events.APIGatewayProxyResponse{
		StatusCode: resp.StatusCode,
		Body:       fmt.Sprintf("%d tweets deleted", destroyed),
	}, nil
}

func main() {
	lambda.Start(handler)
}
