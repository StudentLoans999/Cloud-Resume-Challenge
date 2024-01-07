provider "aws" {
  region = "us-east-1"
  # Optional: specify credentials here or through other means
}

resource "aws_s3_bucket" "CRC_bucket" {
  bucket = "davidrichey.org"
  acl    = "public-read"

  website {
    index_document = "index.html"
    error_document = "error.html"
  }
}

resource "aws_dynamodb_table" "visitor_count" {
  name           = "Table-CRC"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "id"

  attribute {
    name = "id"
    type = "S"
  }
}

resource "aws_iam_role" "lambda_role" {
  name = "lambda_execution_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "lambda.amazonaws.com"
        },
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "dynamodb_full_access" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonDynamoDBFullAccess"
}

resource "aws_lambda_function" "visitor_counter" {
  function_name = "visitorCounter"
  runtime       = "python3.10"
  handler       = "lambda_function.lambda_handler"

  role          = aws_iam_role.lambda_role.arn

  # Example for Lambda code in S3:
  # s3_bucket = "your-lambda-code-bucket"
  # s3_key    = "your-lambda-code.zip"

  # For inline code, use the `filename` or `source_code` argument
  # ... other configurations
}

resource "aws_lambda_function_url" "visitor_counter_url" {
  function_name     = aws_lambda_function.visitor_counter.function_name
  authorization_type = "NONE"

  cors {
    allow_credentials = false
    allow_headers     = ["*"]
    allow_methods     = ["GET"]
    allow_origins     = ["*"]
    max_age           = 3600
  }
}

output "lambda_function_url" {
  value = aws_lambda_function_url.visitor_counter_url.function_url
}
