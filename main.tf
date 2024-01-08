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

resource "aws_cloudfront_origin_access_identity" "oai" {
  comment = "OAI for S3 bucket"
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
      },
      {
        Sid      = "CloudFrontAccess"
        Effect   = "Allow",
        Principal = {
          AWS = aws_cloudfront_origin_access_identity.oai.iam_arn
        },
        Action   = "s3:GetObject",
        Resource = [
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
  bucket = "davidrichey.org"
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
  bucket = "davidrichey.org"
  
  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "error.html"
  }
}

resource "aws_acm_certificate" "cert" {
  domain_name       = "*.davidrichey.org"
  validation_method = "DNS"

  tags = {
    Name = "myDomainCert"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_acm_certificate" "cert" {
  domain_name       = "davidrichey.org"
  validation_method = "DNS"
  subject_alternative_names = ["*.davidrichey.org"]  # Include if you want to cover subdomains

  // ... other configuration ...
}

resource "aws_acm_certificate_validation" "cert" {
  certificate_arn         = aws_acm_certificate.cert.arn
  validation_record_fqdns = [for record in aws_route53_record.cert_validation : record.fqdn]
}

resource "aws_route53_record" "cert_validation" {
  for_each = {
    for dvo in aws_acm_certificate.cert.domain_validation_options : dvo.domain_name => {
      name    = dvo.resource_record_name
      type    = dvo.resource_record_type
      records = [dvo.resource_record_value]
    }
  }

  name    = each.value.name
  type    = each.value.type
  zone_id = aws_route53_zone.primary.zone_id
  records = each.value.records
  ttl     = 60
}

resource "aws_route53_zone" "primary" {
  name = "davidrichey.org"
}

resource "aws_route53_record" "cloudfront_alias" {
  zone_id = aws_route53_zone.primary.zone_id
  name    = "*.davidrichey.org"
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.s3_distribution.domain_name
    zone_id                = aws_cloudfront_distribution.s3_distribution.hosted_zone_id
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "cloudfront_apex_alias" {
  zone_id = aws_route53_zone.primary.zone_id
  name    = "davidrichey.org"
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.s3_distribution.domain_name
    zone_id                = aws_cloudfront_distribution.s3_distribution.hosted_zone_id
    evaluate_target_health = false
  }
}

#resource "aws_route53_record" "subdomain_a_record" {
#  zone_id = aws_route53_zone.primary.zone_id
#  name    = "*.davidrichey.org" 
#  type    = "A"

  #alias {
  #  name = aws_cloudfront_distribution.s3_distribution.domain_name
  #  zone_id = aws_cloudfront_distribution.s3_distribution.hosted_zone_id
  #  evaluate_target_health = false
#  }
#}

resource "aws_route53_record" "a_record" {
  zone_id = aws_route53_zone.primary.zone_id
  name    = "davidrichey.org" 
  type    = "A"

  alias {
    name = aws_cloudfront_distribution.s3_distribution.domain_name
    zone_id = aws_cloudfront_distribution.s3_distribution.hosted_zone_id
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "cname" {
  zone_id = aws_route53_zone.primary.zone_id
  name    = "davidrichey.org"  # subdomain
  type    = "CNAME"
  ttl     = 300
  records = [aws_cloudfront_distribution.s3_distribution.domain_name]
}


resource "aws_cloudfront_distribution" "s3_distribution" {
  origin {
    domain_name = aws_s3_bucket.CRC_bucket.bucket_regional_domain_name
    origin_id   = "CRC_bucket"

    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.oai.cloudfront_access_identity_path
    }
  }

  enabled             = true
  default_root_object = "index.html"

  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "CRC_bucket"

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "redirect-to-https"
  }

  price_class = "PriceClass_All"

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  aliases = ["*.davidrichey.org", "davidrichey.org"]

  viewer_certificate {
    acm_certificate_arn            = aws_acm_certificate.cert.arn
    ssl_support_method             = "sni-only"
    minimum_protocol_version       = "TLSv1.2_2021"
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

output "s3_bucket_name" {
  description = "The name of the S3 bucket"
  value       = aws_s3_bucket.CRC_bucket.bucket
}

output "s3_bucket_website_endpoint" {
  description = "The website endpoint URL of the S3 bucket"
  value       = aws_s3_bucket.CRC_bucket.website
}

output "cloudfront_distribution_domain_name" {
  description = "The domain name of the CloudFront distribution"
  value       = aws_cloudfront_distribution.s3_distribution.domain_name # replace my_distribution with CloudFront distribution
}

output "cloudfront_distribution_id" {
  description = "The ID of the CloudFront distribution"
  value       = aws_cloudfront_distribution.s3_distribution.id
}

output "acm_certificate_arn" {
  description = "The ARN of the ACM certificate"
  value       = aws_acm_certificate.cert.arn
}

output "route53_hosted_zone_id" {
  description = "The ID of the Route 53 hosted zone"
  value       = aws_route53_zone.primary.zone_id
}

output "ns_records_for_domain" {
  description = "Name server records for the hosted zone"
  value       = aws_route53_zone.primary.name_servers
}

output "dynamodb_table_name" {
  description = "The name of the DynamoDB table"
  value       = aws_dynamodb_table.visitor_count.name
}

output "lambda_function_name" {
  description = "The name of the Lambda function"
  value       = aws_lambda_function.visitor_counter.function_name
}

output "lambda_function_arn" {
  description = "The ARN of the Lambda function"
  value       = aws_lambda_function.visitor_counter.arn
}

output "lambda_function_url" {
  value = aws_lambda_function_url.visitor_counter_url.function_url
}