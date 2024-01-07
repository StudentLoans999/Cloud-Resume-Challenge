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

resource "aws_s3_bucket_ownership_controls" "CRC_bucket" {
  bucket = aws_s3_bucket.CRC_bucket.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_public_access_block" "CRC_bucket" {
  bucket = aws_s3_bucket.CRC_bucket.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_acl" "CRC_bucket" {
  depends_on = [
    aws_s3_bucket_ownership_controls.CRC_bucket,
    aws_s3_bucket_public_access_block.CRC_bucket,
  ]

  bucket = aws_s3_bucket.CRC_bucket.id
  acl    = "public-read"
}

resource "aws_s3_bucket_policy" "CRC_bucket_bucket_policy" {
  bucket = aws_s3_bucket.CRC_bucket.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid = "PublicRead"
        Effect = "Allow",
        Principal = "*",
        Action = "s3:GetObject",
        Resource = "${aws_s3_bucket.CRC_bucket.arn}/*"
      }
    ]
  })
}


resource "aws_s3_bucket" "CRC_bucket" {
  bucket = "terraformbucket.org"
}

resource "aws_s3_object" "index" {
  bucket = aws_s3_bucket.CRC_bucket.id
  key    = "index.html"
  source = "index.html"
}

resource "aws_s3_object" "error" {
  bucket = aws_s3_bucket.CRC_bucket.id
  key    = "error.html"
  source = "error.html"
}

resource "aws_s3_object" "js" {
  bucket = aws_s3_bucket.CRC_bucket.id
  key    = "script.js"
  source = "script.js"
}

resource "aws_s3_object" "css" {
  bucket = aws_s3_bucket.CRC_bucket.id
  key    = "style.css"
  source = "style.css"
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
    allow_origins     = ["*"]
  }
}

output "lambda_function_url" {
  value = aws_lambda_function_url.visitor_counter_url.function_url
}
