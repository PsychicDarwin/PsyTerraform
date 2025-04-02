output "s3_bucket_names" {
  description = "Names of the created S3 buckets"
  value       = { for k, v in aws_s3_bucket.psycore_buckets : k => v.id }
}

output "s3_bucket_arns" {
  description = "ARNs of the created S3 buckets"
  value       = { for k, v in aws_s3_bucket.psycore_buckets : k => v.arn }
}

output "iam_role_arn" {
  description = "ARN of the created IAM role"
  value       = aws_iam_role.psycore_role.arn
}

output "team_member_credentials" {
  description = "All credentials for team members (usernames, access keys, and passwords)"
  value = {
    for user in var.team_members : user => {
      username    = aws_iam_user.psycore_user[user].name
      access_key  = aws_iam_access_key.psycore_user_key[user].id
      secret_key  = aws_iam_access_key.psycore_user_key[user].secret
      password    = aws_iam_user_login_profile.psycore_user_login[user].password
    }
  }
  sensitive = true
}

output "cloudtrail_bucket_name" {
  description = "Name of the CloudTrail S3 bucket"
  value       = aws_s3_bucket.cloudtrail_bucket.id
}

output "cloudwatch_log_group" {
  description = "CloudWatch Log Group for CloudTrail logs"
  value       = aws_cloudwatch_log_group.cloudtrail_log_group.name
}