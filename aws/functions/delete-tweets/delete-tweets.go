package main

import (
	"context"
	"fmt"
	"log"
	"time"

	"github.com/aws/aws-lambda-go/events"
	"github.com/aws/aws-lambda-go/lambda"
	"github.com/aws/aws-sdk-go/aws/session"
	"github.com/aws/aws-sdk-go/service/ssm"
	"github.com/dghubble/go-twitter/twitter"
	"github.com/dghubble/oauth1"
)

func handler(_ events.APIGatewayProxyRequest) (events.APIGatewayProxyResponse, error) {
	ssmsvc := ssm.New(session.Must(session.NewSession()))

	config := oauth1.NewConfig(
		getSecret(ssmsvc, "/DeleteTweets/TwitterClientId"),
		getSecret(ssmsvc, "/DeleteTweets/TwitterClientSecret"),
	)
	token := oauth1.NewToken(
		getSecret(ssmsvc, "/DeleteTweets/TwitterAccessToken"),
		getSecret(ssmsvc, "/DeleteTweets/TwitterAccessSecret"),
	)

	httpClient := config.Client(context.Background(), token)
	client := twitter.NewClient(httpClient)

	tweets, resp, err := client.Timelines.UserTimeline(&twitter.UserTimelineParams{Count: 100})
	if err != nil {
		log.Fatal(err)
	}

	fourDaysAgo := time.Now().AddDate(0, 0, -4)
	destroyed := 0

	// Delete any tweet older than three days.
	for _, tweet := range tweets {
		tweetTime, _ := time.Parse(time.RubyDate, tweet.CreatedAt)
		if tweetTime.Before(fourDaysAgo) {
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

func getSecret(s *ssm.SSM, keyName string) string {
	withDecryption := true
	param, err := s.GetParameter(&ssm.GetParameterInput{
		Name:           &keyName,
		WithDecryption: &withDecryption,
	})
	if err != nil {
		panic(err)
	}

	return *param.Parameter.Value
}
