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
	"github.com/aws/aws-xray-sdk-go/xray"
	"github.com/dghubble/go-twitter/twitter"
	"github.com/dghubble/oauth1"
	"github.com/honeycombio/opentelemetry-exporter-go/honeycomb"
	"go.opentelemetry.io/otel/api/global"
	"go.opentelemetry.io/otel/api/kv"
	sdktrace "go.opentelemetry.io/otel/sdk/trace"
)

func handler(ctx context.Context, _ events.APIGatewayProxyRequest) (events.APIGatewayProxyResponse, error) {
	ssmsvc := ssm.New(session.Must(session.NewSession()))

	exporter, err := honeycomb.NewExporter(
		honeycomb.Config{
			APIKey: getSecret(ssmsvc, "/Honeycomb/APIKey"),
		},
		honeycomb.TargetingDataset("delete-tweets"),
		honeycomb.WithServiceName("delete-tweets aws lambda"),
		honeycomb.WithDebugEnabled())
	if err != nil {
		log.Fatal(err)
	}
	defer exporter.Close()

	tp, err := sdktrace.NewProvider(sdktrace.WithConfig(sdktrace.Config{DefaultSampler: sdktrace.AlwaysSample()}),
		sdktrace.WithSyncer(exporter))
	if err != nil {
		log.Fatal(err)
	}
	global.SetTraceProvider(tp)

	tracer := global.TraceProvider().Tracer("aws/lambda/delete-tweets")

	ctx, span := tracer.Start(ctx, "delete-tweets")
	defer span.End()

	config := oauth1.NewConfig(
		getSecret(ssmsvc, "/DeleteTweets/TwitterClientId"),
		getSecret(ssmsvc, "/DeleteTweets/TwitterClientSecret"),
	)
	token := oauth1.NewToken(
		getSecret(ssmsvc, "/DeleteTweets/TwitterAccessToken"),
		getSecret(ssmsvc, "/DeleteTweets/TwitterAccessSecret"),
	)

	httpClient := xray.Client(config.Client(ctx, token))
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

	span.AddEvent(ctx, "results", kv.Int("tweets_deleted", destroyed))

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
