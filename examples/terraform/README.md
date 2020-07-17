# Deploying a PyTorch Lambda Function with Terraform

## Terraform

This isn't meant to be a full tutorial about [Terraform](https://www.terraform.io/), just a demonstration of how to deploy this Lambda Layer using the tool. If you want more details about Terraform in general I recommend reading through their [docs](https://www.terraform.io/docs/providers/aws/index.html) and working through their [tutorials](https://learn.hashicorp.com/terraform) to start.

## Terraform Configuration

Because this zipped layer is too big to upload directly to a Lambda Layer, we have to use the alternative option of first uploading to S3 and referencing the S3 object in the Lambda Layer. We do do that with the following Terraform which creates the S3 bucket, puts our zipped layer in the bucket, and references that object during the creation of a Lambda Layer:

```HCL
resource aws_s3_bucket lambda_layers_bucket {
  bucket = "lambda-layers-${data.aws_region.current.name}-${data.aws_caller_identity.current.account_id}"

  versioning {
    enabled = "true"
  }

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }
}

resource aws_s3_bucket_object pytorch_layer_zip {
  bucket        = aws_s3_bucket.lambda_layers_bucket.bucket
  key           = "PyTorch.zip"
  source        = "layers/PyTorch.zip"
  etag          = filemd5("layers/PyTorch.zip")
}

resource aws_lambda_layer_version pytorch_layer {
  layer_name = "PyTorch-Example"
  s3_bucket  = aws_s3_bucket.lambda_layers_bucket.bucket
  s3_key     = aws_s3_bucket_object.pytorch_layer_zip.id

  compatible_runtimes = ["python3.8"]
}
```

Then to use the layer in our Lambda function, we just have to populate the function resources' `layers` field with a reference to the layer's ARN:

```HCL
resource aws_lambda_function pytorch_lambda {
  filename      = data.archive_file.pytorch_lambda_zip.output_path
  function_name = "PyTorch-Example"
  role          = aws_iam_role.pytorch_lambda_role.arn
  handler       = "main.main"
  runtime       = "python3.8"
  memory_size   = 1024
  timeout       = 60
  layers        = [aws_lambda_layer_version.pytorch_layer.arn]
}
```

## Deploying

These steps assume you've already built the Lambda Layer using this repo and have the zipped layer stored as `layers/PyTorch.zip`. You can point this to another artifact in [main.tf](./main.tf) if needed.

This example also doesn't bother to deal with [remote state](https://www.terraform.io/docs/state/remote.html) and will keep the state of the deployed resources locally. For a production use case you should configure a remote backend appropriately utilizing something like an [S3 backend](https://www.terraform.io/docs/backends/types/s3.html).

1) Install dependencies:

    This example depends on Terraform. If you don't already have it installed you can follow the directions [here](https://learn.hashicorp.com/terraform/getting-started/install.html) to get it.

2) Configure your AWS credentials to point to your account. There are several ways to do [this](https://docs.aws.amazon.com/sdk-for-java/v1/developer-guide/setup-credentials.html).

3) Deploy:

    ```sh
    terraform init
    terraform apply
    ```
