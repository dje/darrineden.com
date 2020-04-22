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

func handler(req events.APIGatewayProxyRequest) (events.APIGatewayProxyResponse, error) {
	var t WebTraceOpenCensus

	htmlHeader := make(map[string]string)
	htmlHeader["Content-Type"] = "text/html"

	err := json.NewDecoder(strings.NewReader(req.Body)).Decode(&t)
	if err != nil {
		return events.APIGatewayProxyResponse{
			Body:       fmt.Sprintf("Cannot decode JSON: %s", err.Error()),
			StatusCode: 400,
		}, nil
	}

	dbsvc := dynamodb.New(session.Must(session.NewSession()))

	ttl := time.Now().Add(ttlExpireDays).Unix()
	for _, span := range t.Spans {
		av, err := dynamodbattribute.MarshalMap(span)
		if err != nil {
			return events.APIGatewayProxyResponse{
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
			return events.APIGatewayProxyResponse{
				Body:       fmt.Sprintf("Cannot put span item into db: %s", err.Error()),
				StatusCode: 500,
			}, nil
		}

	}
	return events.APIGatewayProxyResponse{
		Body:       "Trace stored successfully",
		Headers:    htmlHeader,
		StatusCode: 200,
	}, nil
}

func main() {
	lambda.Start(handler)
}

type WebTraceOpenCensus struct {
	Node struct {
		Identifier struct {
			HostName       string    `json:"hostName"`
			StartTimestamp time.Time `json:"startTimestamp"`
		} `json:"identifier"`
		LibraryInfo struct {
			Language           int    `json:"language"`
			CoreLibraryVersion string `json:"coreLibraryVersion"`
			ExporterVersion    string `json:"exporterVersion"`
		} `json:"libraryInfo"`
		ServiceInfo struct {
			Name string `json:"name"`
		} `json:"serviceInfo"`
	} `json:"node"`
	Resource struct {
		Labels struct {
			TelemetrySdkLanguage string `json:"telemetry.sdk.language"`
			TelemetrySdkName     string `json:"telemetry.sdk.name"`
			TelemetrySdkVersion  string `json:"telemetry.sdk.version"`
		} `json:"labels"`
	} `json:"resource"`
	Spans []struct {
		TraceID    string `json:"traceId"`
		SpanID     string `json:"spanId"`
		Tracestate struct {
		} `json:"tracestate"`
		Name struct {
			Value              string `json:"value"`
			TruncatedByteCount int    `json:"truncatedByteCount"`
		} `json:"name"`
		Kind       int       `json:"kind"`
		StartTime  time.Time `json:"startTime"`
		EndTime    time.Time `json:"endTime"`
		Attributes struct {
			DroppedAttributesCount int `json:"droppedAttributesCount"`
			AttributeMap           json.RawMessage
		} `json:"attributes"`
		TimeEvents struct {
			TimeEvent                 []interface{} `json:"timeEvent"`
			DroppedAnnotationsCount   int           `json:"droppedAnnotationsCount"`
			DroppedMessageEventsCount int           `json:"droppedMessageEventsCount"`
		} `json:"timeEvents"`
		Status struct {
			Code int `json:"code"`
		} `json:"status"`
		SameProcessAsParentSpan bool `json:"sameProcessAsParentSpan"`
		Links                   struct {
			Link              []interface{} `json:"link"`
			DroppedLinksCount int           `json:"droppedLinksCount"`
		} `json:"links"`
	} `json:"spans"`
}
