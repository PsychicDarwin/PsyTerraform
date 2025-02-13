output "s3_bucket_name" {
  description = "Name of the created S3 bucket"
  value       = aws_s3_bucket.psycore_bucket.id
}

output "s3_bucket_arn" {
  description = "ARN of the created S3 bucket"
  value       = aws_s3_bucket.psycore_bucket.arn
}

output "iam_role_arn" {
  description = "ARN of the created IAM role"
  value       = aws_iam_role.psycore_role.arn
}

output "iam_user_name" {
  description = "Name of the created IAM user"
  value       = aws_iam_user.psycore_user.name
}

output "iam_user_access_key" {
  description = "Access key for the created IAM user"
  value       = aws_iam_access_key.psycore_user_key.id
  sensitive   = true
}

output "iam_user_secret_key" {
  description = "Secret key for the created IAM user"
  value       = aws_iam_access_key.psycore_user_key.secret
  sensitive   = true
}

output "console_password" {
  description = "Initial console password for the IAM user (change required on first login)"
  value       = aws_iam_user_login_profile.psycore_user_login.password
  sensitive   = true
}

output "cloudtrail_bucket_name" {
  description = "Name of the CloudTrail S3 bucket"
  value       = aws_s3_bucket.cloudtrail_bucket.id
}

output "cloudwatch_log_group" {
  description = "CloudWatch Log Group for CloudTrail logs"
  value       = aws_cloudwatch_log_group.cloudtrail_log_group.name
}