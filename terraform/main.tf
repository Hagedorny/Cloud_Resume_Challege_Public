// ----------------------------
// Terraform Settings
// ----------------------------
terraform {
  required_version = ">= 1.3.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

// ----------------------------
// AWS Provider Configuration
// ----------------------------
provider "aws" {
  region = var.aws_region
}

// ----------------------------
// Local Variables
// ----------------------------
locals {
  enabled    = var.create_examples
  site_files = fileset("${path.module}/../site", "**/*.*")
}

// ----------------------------
// S3 Bucket: Resume Static Site
// ----------------------------
resource "aws_s3_bucket" "resume_site" {
  bucket        = var.resume_bucket_name
  force_destroy = true

  tags = {
    Project = "CloudResume"
  }
}

resource "aws_s3_bucket_versioning" "resume_site_versioning" {
  bucket = aws_s3_bucket.resume_site.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_website_configuration" "resume_site_website" {
  bucket = aws_s3_bucket.resume_site.id

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "error.html"
  }
}

resource "aws_s3_bucket_public_access_block" "log_bucket_block" {
  count  = var.log_bucket_public_block_enabled ? 1 : 0
  bucket = aws_s3_bucket.log_bucket.id

  block_public_acls       = true
  ignore_public_acls      = true
  block_public_policy     = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_policy" "resume_site_policy" {
  count  = var.allow_public_access ? 1 : 0
  bucket = aws_s3_bucket.resume_site.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid       = "PublicReadGetObject",
        Effect    = "Allow",
        Principal = "*",
        Action    = "s3:GetObject",
        Resource  = "${aws_s3_bucket.resume_site.arn}/*"
      }
    ]
  })
}


// ----------------------------
// Upload Each Site File to S3
// ----------------------------
resource "aws_s3_object" "site_files" {
  for_each = { for file in local.site_files : file => file }

  bucket = aws_s3_bucket.resume_site.id
  key    = "CRC/${each.key}"
  source = "${path.module}/../site/${each.value}"
  etag   = filemd5("${path.module}/../site/${each.value}")

  content_type = lookup({
    html = "text/html"
    css  = "text/css"
    js   = "application/javascript"
    json = "application/json"
    png  = "image/png"
    jpg  = "image/jpeg"
    jpeg = "image/jpeg"
    svg  = "image/svg+xml"
  }, regex("^.*\\.([^.]+)$", each.key)[0], "application/octet-stream")

  server_side_encryption = "AES256"
  lifecycle {
    ignore_changes = [etag] # Optimization: prevent unnecessary re-uploads
  }
}


// ----------------------------
// Access Logging Setup
// ----------------------------

resource "aws_s3_bucket" "log_bucket" {
  bucket        = "cloud-resume-access-logs-fixed"
  force_destroy = true

  tags = {
    Purpose = "AccessLogs"
  }
}

resource "aws_s3_bucket_logging" "resume_site_logging" {
  bucket        = aws_s3_bucket.resume_site.id
  target_bucket = aws_s3_bucket.log_bucket.id
  target_prefix = "log/"
}

data "aws_caller_identity" "current" {}

resource "aws_s3_bucket_policy" "log_bucket_policy" {
  bucket = aws_s3_bucket.log_bucket.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid       = "AllowS3Logging",
        Effect    = "Allow",
        Principal = { Service = "logging.s3.amazonaws.com" },
        Action    = "s3:PutObject",
        Resource  = "${aws_s3_bucket.log_bucket.arn}/log/*",
        Condition = {
          StringEquals = {
            "aws:SourceAccount" = data.aws_caller_identity.current.account_id
          }
        }
      }
    ]
  })
}
resource "aws_s3_bucket_public_access_block" "resume_site_block" {
  bucket = aws_s3_bucket.resume_site.id

  block_public_acls       = var.block_acls
  ignore_public_acls      = var.block_acls
  block_public_policy     = var.block_public_policy
  restrict_public_buckets = var.block_public_policy
}

// ----------------------------
// DynamoDB for Visitor Count
// ----------------------------
resource "aws_dynamodb_table" "visitor_count" {
  name         = "VisitorCount"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "id"

  attribute {
    name = "id"
    type = "S"
  }

  tags = {
    Project = "CloudResume"
  }
}

// ----------------------------
// Lambda IAM Role + Function
// ----------------------------
resource "aws_iam_role" "lambda_exec_role" {
  name = "lambda-exec-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "lambda.amazonaws.com"
        },
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_lambda_function" "visitor_counter" {
  function_name = "UpdateVisitorCount"
  role          = aws_iam_role.lambda_exec_role.arn
  handler       = "lambda_function.lambda_handler"
  runtime       = "python3.12"
  timeout       = 3

  filename         = "${path.module}/../lambda/lambda.zip"
  source_code_hash = filebase64sha256("${path.module}/../lambda/lambda.zip")

  environment {
    variables = {
      TABLE_NAME = "VisitorCount"
    }
  }

  lifecycle {
    ignore_changes = [
      filename,
      source_code_hash
    ]
  }

  depends_on = [
    aws_iam_role.lambda_exec_role,
    aws_iam_role_policy.lambda_policy
  ]
}

resource "aws_iam_role_policy" "lambda_policy" {
  name = "lambda-dynamodb-access"
  role = aws_iam_role.lambda_exec_role.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "dynamodb:GetItem",
          "dynamodb:UpdateItem"
        ],
        Resource = "arn:aws:dynamodb:var.aws_region:${data.aws_caller_identity.current.account_id}:table/VisitorCount"
      },
      {
        Effect = "Allow",
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        Resource = "arn:aws:logs:var.aws_region:${data.aws_caller_identity.current.account_id}:log-group:/aws/lambda/UpdateVisitorCount:*"
      }
    ]
  })
}

