provider "aws" {
  region = var.aws_region
}

# S3 Bucket for service use
resource "aws_s3_bucket" "psycore_bucket" {
  bucket = lower("${var.service_name}-documents-${data.aws_caller_identity.current.account_id}")

  tags = {
    Name        = "${var.service_name} Documents"
    Environment = var.environment
    Project     = var.project_name
    Service     = var.service_name
  }
}

# Bucket versioning
resource "aws_s3_bucket_versioning" "psycore_bucket_versioning" {
  bucket = aws_s3_bucket.psycore_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}

# Private access only
resource "aws_s3_bucket_public_access_block" "psycore_bucket_access" {
  bucket = aws_s3_bucket.psycore_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Server-side encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "psycore_bucket_encryption" {
  bucket = aws_s3_bucket.psycore_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# S3 Bucket for CloudTrail logs (Monitoring IAM activity)
resource "aws_s3_bucket" "cloudtrail_bucket" {
  bucket = lower("${var.service_name}-cloudtrail-logs-${data.aws_caller_identity.current.account_id}")

  tags = {
    Name        = "${var.service_name} CloudTrail Logs"
    Environment = var.environment
    Project     = var.project_name
    Service     = var.service_name
  }
}

# CloudTrail bucket versioning
resource "aws_s3_bucket_versioning" "cloudtrail_bucket_versioning" {
  bucket = aws_s3_bucket.cloudtrail_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}

# CloudTrail bucket encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "cloudtrail_bucket_encryption" {
  bucket = aws_s3_bucket.cloudtrail_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_policy" "cloudtrail_bucket_policy" {
  bucket = aws_s3_bucket.cloudtrail_bucket.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AWSCloudTrailAclCheck"
        Effect = "Allow"
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        }
        Action   = "s3:GetBucketAcl"
        Resource = aws_s3_bucket.cloudtrail_bucket.arn
      },
      {
        Sid    = "AWSCloudTrailWrite"
        Effect = "Allow"
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        }
        Action   = "s3:PutObject"
        Resource = "${aws_s3_bucket.cloudtrail_bucket.arn}/*"
        Condition = {
          StringEquals = {
            "s3:x-amz-acl" = "bucket-owner-full-control"
          }
        }
      },
      {
        Sid    = "AWSCloudTrailBucketList"
        Effect = "Allow"
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        }
        Action   = "s3:ListBucket"
        Resource = aws_s3_bucket.cloudtrail_bucket.arn
      },
      {
        Sid    = "AWSCloudTrailWriteOrg"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action   = "s3:PutObject"
        Resource = "${aws_s3_bucket.cloudtrail_bucket.arn}/*"
        Condition = {
          StringEqualsIfExists = {
            "s3:x-amz-acl"      = "bucket-owner-full-control",
            "aws:SourceArn"     = "arn:aws:cloudtrail:${var.aws_region}:${data.aws_caller_identity.current.account_id}:trail/${var.service_name}Trail",
            "aws:SourceAccount" = data.aws_caller_identity.current.account_id
          }
        }
      }
    ]
  })
}

# CloudTrail
resource "aws_cloudtrail" "psycore_trail" {
  name                          = "${var.service_name}Trail"
  s3_bucket_name               = aws_s3_bucket.cloudtrail_bucket.id
  include_global_service_events = true
  is_multi_region_trail        = true
  enable_logging               = true

  # Enable CloudWatch Logs
  cloud_watch_logs_group_arn = "${aws_cloudwatch_log_group.cloudtrail_log_group.arn}:*"
  cloud_watch_logs_role_arn  = aws_iam_role.cloudtrail_cloudwatch_role.arn

  event_selector {
    read_write_type           = "All"
    include_management_events = true
  }

  tags = {
    Name        = "${var.service_name} Trail"
    Environment = var.environment
    Project     = var.project_name
    Service     = var.service_name
  }
}

# CloudWatch Log Group for CloudTrail
resource "aws_cloudwatch_log_group" "cloudtrail_log_group" {
  name              = "/aws/cloudtrail/${var.service_name}"
  retention_in_days = 30

  tags = {
    Environment = var.environment
    Project     = var.project_name
    Service     = var.service_name
  }
}

# IAM Role for CloudTrail to CloudWatch Logs
resource "aws_iam_role" "cloudtrail_cloudwatch_role" {
  name = "${var.service_name}CloudTrailCloudWatchRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        }
      }
    ]
  })
}

# IAM Policy for CloudTrail to CloudWatch Logs
resource "aws_iam_role_policy" "cloudtrail_cloudwatch_policy" {
  name = "${var.service_name}CloudTrailCloudWatchPolicy"
  role = aws_iam_role.cloudtrail_cloudwatch_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "${aws_cloudwatch_log_group.cloudtrail_log_group.arn}:*"
      }
    ]
  })
}

# IAM Role for service
resource "aws_iam_role" "psycore_role" {
  name = "${var.service_name}ServiceRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "bedrock.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Project = var.project_name
    Service = var.service_name
    Environment = var.environment
  }
}

# IAM User
resource "aws_iam_user" "psycore_user" {
  name = lower("${var.service_name}-service-user")
  
  tags = {
    Project = var.project_name
    Service = var.service_name
    Environment = var.environment
  }
}

# Login profile for console access
resource "aws_iam_user_login_profile" "psycore_user_login" {
  user                    = aws_iam_user.psycore_user.name
  password_reset_required = true
  password_length        = 20
}

# Access Key for the user
resource "aws_iam_access_key" "psycore_user_key" {
  user = aws_iam_user.psycore_user.name
}

# Custom policy for Bedrock and S3 access
resource "aws_iam_policy" "psycore_policy" {
  name        = "${var.service_name}ServicePolicy"
  description = "Policy for ${var.service_name} service access to Bedrock and S3"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:ListBucket"
        ]
        Resource = aws_s3_bucket.psycore_bucket.arn
      },
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:ListAllMyBuckets"
        ]
        Resource = "${aws_s3_bucket.psycore_bucket.arn}/*"
      },
      {
        Effect = "Deny"
        Action = [
          "s3:ListAllMyBuckets"
        ]
        Resource = "*"
      },
      {
        "Effect": "Allow",
        "Action": [
            "bedrock:ListGuardrails",
            "bedrock:ListInferenceProfiles",
            "bedrock:ListProvisionedModelThroughputs",
            "sagemaker:ListHubContents",
            "bedrock:GetFoundationModelAvailability",
            "bedrock:ListMarketplaceModelEndpoints",
            "bedrock:ListFoundationModels",
            "bedrock:GetFoundationModel",
            "bedrock:ListCustomModels",
            "bedrock:GetCustomModel",
            "bedrock:ListModelCustomizationJobs",
            "bedrock:GetModelCustomizationJob",
            "bedrock:InvokeModel",
            "bedrock:InvokeModelWithResponseStream"
        ],
        "Resource": "*"
      },
      {
        Effect = "Allow"
        Action = [
          "opensearch:*"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "cloudtrail:LookupEvents",
          "cloudtrail:GetTrailStatus",
          "cloudwatch:GetMetricData",
          "logs:DescribeLogStreams",
          "logs:GetLogEvents",
          "logs:FilterLogEvents"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "iam:ChangePassword"
        ]
        Resource = "arn:aws:iam::*:user/${aws_iam_user.psycore_user.name}"
      }
    ]
  })

  tags = {
    Project = var.project_name
    Service = var.service_name
    Environment = var.environment
  }
}

# Attach policy to role
resource "aws_iam_role_policy_attachment" "psycore_role_policy" {
  role       = aws_iam_role.psycore_role.name
  policy_arn = aws_iam_policy.psycore_policy.arn
}

# Attach policy to user
resource "aws_iam_user_policy_attachment" "psycore_user_policy" {
  user       = aws_iam_user.psycore_user.name
  policy_arn = aws_iam_policy.psycore_policy.arn
}

# Get current caller identity
data "aws_caller_identity" "current" {}
