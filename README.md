# Create an AWS Lambda Layer for PyTorch

## tldr

Running the following command from this root directory with your specified versions will create a `layers/PyTorch.zip` file that can be used as an AWS Lambda layer:

```shell
./scripts/make-layer.sh --python=3.8 --torch=1.5.1 --torchvision=0.6.1
```

## Background

Getting PyTorch running in AWS Lambda is a little tricky given PyTorch's large package size and [Lambda's package size limits](https://docs.aws.amazon.com/lambda/latest/dg/gettingstarted-limits.html).

One solution is to include a zipped torch package directly in your deployment package. More details for that approach are provided by Davy Neven [here](https://segments.ai/blog/pytorch-on-lambda).

Another solution is to include your external Python libraries in an AWS Lambda Layer. This is a great approach if you have multiple models running and want to share the packages across functions. It also help keeps your function deployment package small since all of the heavy lifting will be done within the layer. This is the approach suggested by fast.ai which also provides info about two public PyTorch Lambda Layers that can be used [here](https://course.fast.ai/deployment_aws_lambda.html).

Both of these solutions ultimately zip up the torch package and unzip it into Lambda's `/tmp` directory at runtime.

One issue is that the public Lambda Layers mentioned by fast.ai are a bit outdated and there could be other reasons why you would want to manage your own layer as opposed to relying on the public layer. This script enables you to build the layer for any given Python + torch versions, as well as specified versions of torchvision and torchaudio if needed, but follows the same zip/unzip pattern + usage used in both of the above solutions.

## Dependencies

This script relies on Docker to package the Python libraries in a simulated Lambda environment. You can install Docker Desktop for your OS by following the directions [here](https://docs.docker.com/get-docker/).

## Building the zipped layer

1) Clone this repo with:

    ```shell
    $ git clone git@github.com:JTunis/create-pytorch-lambda-layer.git && \
    cd create-pytorch-lambda-layer
    ```

2) Run the script with your specified Python/package versions (Python and torch versions are required, and if torchvision/torchaudio versions are given then those packages will be included as well, otherwise they're omitted):

    ```shell
    $ ./scripts/make-layer.sh \
    --python=3.8 \
    --torch=1.5.1 \
    --torchvision=0.6.1 \
    --torchaudio=0.5.1
    ```

3) The zipped layer will be created in the newly created `layers/` directory with the name `PyTorch.zip`

## Using the Layer

We include the `unzip_requirements` module in the Lambda Layer and it needs to be imported by your function code inorder to unzip the torch library into `/tmp`. A sample function could look something like this:

```python
try:
    import unzip_requirements
except ImportError:
    pass
import torch


def main(event, context):
    """Entry point for Lambda."""
    print(torch.__version__)

```

They try/except block is there so the same function code can be used locally (where we'll hit the `ImportError` and just use the conda/venv install torch library) as well as in Lambda.

## Deploying the Layer

The zipped layer is over the 50MB limit to be uploaded directly through Lambda's service, so it first has to be stored in an S3 bucket. Then, you can reference the S3 bucket and object key of the zipped file in Lambda.

## Examples

WIP: Deploying with [Terraform](https://www.terraform.io/)

Deploying with [Serverless Framework](./examples/serverless)
