package main

import (
	"encoding/json"
	"fmt"
	"os"
	"strconv"
	"strings"
	"time"

	"github.com/aws/aws-lambda-go/events"
	"github.com/aws/aws-lambda-go/lambda"
	"github.com/aws/aws-sdk-go/aws"
	"github.com/aws/aws-sdk-go/aws/session"
	"github.com/aws/aws-sdk-go/service/dynamodb"
	"github.com/aws/aws-sdk-go/service/dynamodb/dynamodbattribute"
)

const ttlExpireDays = 18 * (time.Hour * 24)

func handler(req events.APIGatewayV2HTTPRequest) (events.APIGatewayV2HTTPResponse, error) {
	var t WebTrace

	err := json.NewDecoder(strings.NewReader(req.Body)).Decode(&t)
	if err != nil {
		return events.APIGatewayV2HTTPResponse{
			Body:       fmt.Sprintf("Cannot decode JSON: %s", err.Error()),
			StatusCode: 400,
		}, nil
	}

	dbsvc := dynamodb.New(session.Must(session.NewSession()))

	ttl := time.Now().Add(ttlExpireDays).Unix()

	for _, rs := range t.ResourceSpans {
		for _, ils := range rs.InstrumentationLibrarySpans {
			for _, span := range ils.Spans {
				av, err := dynamodbattribute.MarshalMap(span)
				if err != nil {
					return events.APIGatewayV2HTTPResponse{
						Body:       fmt.Sprintf("Cannot marshal span to db: %s", err.Error()),
						StatusCode: 500,
					}, nil
				}

				av["ttl"] = &dynamodb.AttributeValue{
					N: aws.String(strconv.FormatInt(ttl, 10)),
				}

				_, err = dbsvc.PutItem(&dynamodb.PutItemInput{
					TableName: aws.String(os.Getenv("TABLE_NAME")),
					Item:      av,
				})
				if err != nil {
					return events.APIGatewayV2HTTPResponse{
						Body:       fmt.Sprintf("Cannot put span item into db: %s", err.Error()),
						StatusCode: 500,
					}, nil
				}
			}
		}
	}

	return events.APIGatewayV2HTTPResponse{
		Body:       `{"message": "Trace stored successfully"}`,
		StatusCode: 200,
	}, nil
}

func main() {
	lambda.Start(handler)
}

type WebTrace struct {
	ResourceSpans []struct {
		Resource struct {
			Attributes []struct {
				Key         string `json:"key"`
				Type        int    `json:"type"`
				StringValue string `json:"stringValue"`
			} `json:"attributes"`
			DroppedAttributesCount int `json:"droppedAttributesCount"`
		} `json:"resource"`
		InstrumentationLibrarySpans []struct {
			Spans []struct {
				TraceID           string `json:"traceId"`
				SpanID            string `json:"spanId"`
				ParentSpanID      string `json:"parentSpanId"`
				Name              string `json:"name"`
				Kind              int    `json:"kind"`
				StartTimeUnixNano int64  `json:"startTimeUnixNano"`
				EndTimeUnixNano   int64  `json:"endTimeUnixNano"`
				Attributes        []struct {
					Key         string `json:"key"`
					Type        int    `json:"type"`
					StringValue string `json:"stringValue"`
				} `json:"attributes"`
				DroppedAttributesCount int `json:"droppedAttributesCount"`
				Events                 []struct {
					TimeUnixNano           int64         `json:"timeUnixNano"`
					Name                   string        `json:"name"`
					Attributes             []interface{} `json:"attributes"`
					DroppedAttributesCount int           `json:"droppedAttributesCount"`
				} `json:"events"`
				DroppedEventsCount int `json:"droppedEventsCount"`
				Status             struct {
					Code int `json:"code"`
				} `json:"status"`
				Links             []interface{} `json:"links"`
				DroppedLinksCount int           `json:"droppedLinksCount"`
			} `json:"spans"`
			InstrumentationLibrary struct {
				Name    string `json:"name"`
				Version string `json:"version"`
			} `json:"instrumentationLibrary"`
		} `json:"instrumentationLibrarySpans"`
	} `json:"resourceSpans"`
}
