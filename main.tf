terraform {
  cloud {
    organization = "david_richey"

    workspaces {
      name = "Cloud-Resume-Challenge"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

resource "aws_s3_bucket" "CRC_bucket" {
  bucket = "terraformbucket.org"
}

resource "aws_s3_object" "index" {
  bucket = aws_s3_bucket.CRC_bucket.id
  key    = "index.html"
  source = "C:\\IT\\AWS\\CRC\\index.html"
}

resource "aws_s3_object" "error" {
  bucket = aws_s3_bucket.CRC_bucket.id
  key    = "error.html"
  source = "C:\\IT\\AWS\\CRC\\error.html"
}

resource "aws_s3_object" "js" {
  bucket = aws_s3_bucket.CRC_bucket.id
  key    = "script.js"
  source = "C:\\IT\\AWS\\CRC\\script.js"
}

resource "aws_s3_object" "css" {
  bucket = aws_s3_bucket.CRC_bucket.id
  key    = "style.css"
  source = "C:\\IT\\AWS\\CRC\\style.css"
}

resource "aws_s3_bucket_website_configuration" "CRC_bucket" {
  bucket = "terraformbucket.org"
  
  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "error.html"
  }
}

data "aws_iam_policy_document" "allow_access_from_another_account" {
  statement {
    principals {
      type        = "AWS"
      identifiers = ["*"]
    }

    actions = [
      "s3:GetObject",
      "s3:ListBucket",
    ]

    resources = [
      aws_s3_bucket.CRC_bucket.arn,
      "${aws_s3_bucket.CRC_bucket.arn}/*",
    ]
  }
}

resource "aws_s3_bucket_policy" "allow_access_from_another_account" {
  bucket = aws_s3_bucket.CRC_bucket.id
  policy = data.aws_iam_policy_document.allow_access_from_another_account.json
}



resource "aws_dynamodb_table" "visitor_count" {
  name           = "Terraform-Table-CRC"
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
  filename      = "lambda_function.zip"
  function_name = "visitorCounter"
  runtime       = "python3.10"
  handler       = "lambda_function.lambda_handler"
  role          = aws_iam_role.lambda_role.arn
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
