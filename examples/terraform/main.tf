terraform {
  required_version = ">= 0.12"
  required_providers {
    aws = ">= 2.35.0"
  }
}

data aws_caller_identity current {}
data aws_region current {}

data archive_file pytorch_lambda_zip {
  type        = "zip"
  source_dir  = "src"
  output_path = "build/function.zip"
}

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

resource aws_iam_role pytorch_lambda_role {
  name = "pytorch_lambda_role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}
