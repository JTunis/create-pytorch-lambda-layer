# Deploying a PyTorch Lambda Function with Serverless Framework

## Serverless Framework

This isn't meant to be a full tutorial about [Serverless Framework](https://www.serverless.com/), just a demonstration of how to deploy this Lambda Layer using the tool. If you want more details about Serverless in general I recommend reading through their [docs](https://www.serverless.com/framework/docs/providers/aws/) and working through their Hello World [examples](https://www.serverless.com/framework/docs/providers/aws/examples/hello-world/python/) to start.

## Serverless Configuration

Deploying a Lambda function utilizing the PyTorch Lambda Layer is pretty straight-forward with Serverless. You just need to create a `layers` block that points to the zip artifact created by this script (with optional compatible runtimes):

```yaml
layers:
  PyTorch:
    package:
      artifact: layers/PyTorch.zip
    compatibleRuntimes:
      - python3.8
```

and reference the layer inside your function configuration as `{configuredLayerName}LambdaLayer`, where `configuredLayerName` is the name of the yaml block configuring your layer above. In this case, "PyTorch":

```yaml
functions:
  pytorch-example:
    handler: main.main
    name: PyTorch-Example
    timeout: 60
    memorySize: 1024
    description: Demonstrates usage of the PyTorch Lambda Layer
    layers:
      - {Ref: PyTorchLambdaLayer}
```

You can find the full Serverless configuration for this example [here](./serverless.yml)

## Deploying

These steps assume you've already built the Lambda Layer using this repo and have the zipped layer stored as `layers/PyTorch.zip`. You can point this to another artifact in [serverless.yml](./serverless.yml) if needed.

1) Install dependencies:

    This will install Serverless Framework iteself as well as the `serverless-deployment-bucket` plugin. This plugin will create the S3 bucket for Serverless deployment artifacts to be stored. If you already have a bucket you are using then this isn't necessary and you can remove the plugin from the config file and point the `deploymentBucket` to your existing bucket.

    ```sh
    npm install
    ```

2) Configure AWS provider:
Rename the `deploymentBucket` in the `provider` block of [serverless.yml](./serverless.yml) to the name of the S3 bucket you want to deploy. Note this name must be globably unique. Also, feel free to change the `region` of deployment for all of these resources.

3) Configure your AWS credentials to point to your account. There are several ways to do [this](https://docs.aws.amazon.com/sdk-for-java/v1/developer-guide/setup-credentials.html).

4) Run Serverless deploy:

    ```sh
    sls deploy
    ```
