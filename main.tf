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

resource "aws_s3_bucket_acl" "CRC_bucket" {
  bucket = aws_s3_bucket.CRC_bucket.id
  acl    = "public-read"
  depends_on = [aws_s3_bucket_ownership_controls.s3_bucket_acl_ownership]
}

resource "aws_s3_bucket_ownership_controls" "s3_bucket_acl_ownership" {
  bucket = aws_s3_bucket.CRC_bucket.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
  depends_on = [aws_s3_bucket_public_access_block.bucket_block_public_access]
}

resource "aws_iam_user" "terraform_david" {
  name = "terraform_david"  # The name of the IAM user
}

resource "aws_s3_bucket_public_access_block" "bucket_block_public_access" {
  bucket = aws_s3_bucket.CRC_bucket.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
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
        Resource = [ 
          "${aws_s3_bucket.CRC_bucket.arn}",
          "${aws_s3_bucket.CRC_bucket.arn}/*"
        ]
      }
    ]
  })
  depends_on = [aws_s3_bucket_public_access_block.bucket_block_public_access]
}



resource "aws_iam_user_policy_attachment" "admin_access" {
  user       = aws_iam_user.terraform_david.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

resource "aws_iam_user_policy_attachment" "apigw_admin" {
  user       = aws_iam_user.terraform_david.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonAPIGatewayAdministrator"
}

resource "aws_iam_user_policy_attachment" "cloudformation_full_access" {
  user       = aws_iam_user.terraform_david.name
  policy_arn = "arn:aws:iam::aws:policy/AWSCloudFormationFullAccess"
}

resource "aws_iam_user_policy_attachment" "lambda_full_access" {
  user       = aws_iam_user.terraform_david.name
  policy_arn = "arn:aws:iam::aws:policy/AWSLambda_FullAccess"
}

resource "aws_iam_user_policy_attachment" "billing" {
  user       = aws_iam_user.terraform_david.name
  policy_arn = "arn:aws:iam::aws:policy/job-function/Billing"
}

resource "aws_iam_user_policy_attachment" "iam_full_access" {
  user       = aws_iam_user.terraform_david.name
  policy_arn = "arn:aws:iam::aws:policy/IAMFullAccess"
}

resource "aws_iam_user_policy_attachment" "iam_user_change_password" {
  user       = aws_iam_user.terraform_david.name
  policy_arn = "arn:aws:iam::aws:policy/IAMUserChangePassword"
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
  name = "visitorCounter_lambda_execution_role"

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

# Attach AWSLambda_FullAccess policy
resource "aws_iam_role_policy_attachment" "lambda_full_access" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/AWSLambda_FullAccess"
}

# Attach AWSLambdaBasicExecutionRole policy
resource "aws_iam_role_policy_attachment" "lambda_basic_execution" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# Attach CloudWatchFullAccess policy
resource "aws_iam_role_policy_attachment" "cloudwatch_full_access" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchFullAccess"
}

# Attach CloudWatchLogsFullAccess policy
resource "aws_iam_role_policy_attachment" "cloudwatch_logs_full_access" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchLogsFullAccess"
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
