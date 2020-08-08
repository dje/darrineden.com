# [darrineden.com](https://darrineden.com)
This is my personal site. I use it to play with technologies I'm curious about.

At the moment that includes [Elm](https://elm-lang.org/), [OpenTelemetry](https://opentelemetry.io/),
and Amazon Web Services' [Cloud Development Kit](https://aws.amazon.com/cdk/)
targeting [DynamoDB](https://aws.amazon.com/dynamodb/) and [Lambda](https://aws.amazon.com/lambda/).

## Netlify
The frontend deploys after a GitHub commit. During this process `make build` runs from the `netlify` directory.

[![Netlify Status](https://api.netlify.com/api/v1/badges/3835ae1e-7244-4ffe-90d3-36dfc37fe4a7/deploy-status)](https://app.netlify.com/sites/darrineden/deploys)

## AWS

### Development

Python and `virtualenv` are required.

```
cd aws
make dev
source .env/bin/activate.fish
```

### Deploy

To deploy the backend switch to the `aws` directory and run `make deploy`.
