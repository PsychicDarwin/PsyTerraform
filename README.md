# PsyCore AWS Infrastructure Setup

⚠️ **IMPORTANT: ONE-TIME INITIALIZATION**
This Terraform configuration performs initial AWS resource setup. It should be run only once to establish the core infrastructure. Subsequent service configurations should be managed through the main Psynfra repository.

## Resources Created

- Private S3 bucket for document storage
- IAM Role with Bedrock and S3 permissions
- IAM User with necessary access and console login
- Access keys for programmatic access
- CloudTrail logging setup with CloudWatch integration
- Required policies and attachments

## Prerequisites

- AWS CLI configured
- Terraform installed
- Appropriate AWS permissions to create resources

## Usage

1. Initialize Terraform:
```bash
terraform init
```

2. Review the planned changes:
```bash
terraform plan
```

3. Apply the configuration:
```bash
terraform apply
```

4. Retrieve credentials:
```bash
# Access Key ID
terraform output iam_user_access_key

# Secret Access Key
terraform output iam_user_secret_key

# Console Password
terraform output console_password
```

## Credential Distribution

1. Local Development:
   - Add to your local `.env` files:
     ```
     AWS_ACCESS_KEY_ID=<access_key>
     AWS_SECRET_ACCESS_KEY=<secret_key>
     AWS_DEFAULT_REGION=eu-west-2
     ```

2. GitHub Organization:
   - Add to Organization Secrets:
     - `AWS_ACCESS_KEY_ID`
     - `AWS_SECRET_ACCESS_KEY`
     - `AWS_DEFAULT_REGION`

3. Console Access:
   - URL: https://console.aws.amazon.com/
   - Username: psycore-service-user
   - Initial password: Retrieved from terraform output
   - Password change required on first login

## Audit and Monitoring

The setup includes comprehensive audit logging:

1. CloudTrail Configuration:
   - Multi-region trail enabled
   - All management events logged
   - 30-day retention in CloudWatch Logs
   - Permanent storage in dedicated S3 bucket

2. Access Controls:
   - Service role/user can only read audit logs
   - Trail modification restricted to admin users
   - CloudTrail bucket manipulation restricted to admin users

3. Monitoring Locations:
   - CloudTrail console for real-time monitoring
   - CloudWatch Logs for log analysis
   - S3 bucket for long-term audit storage

## Security Configuration

- S3 buckets are private by default
- Server-side encryption enabled on all buckets
- Resources in eu-west-2 (London)
- Access keys and console password marked as sensitive
- CloudTrail logs protected from service role modification
- Force password change on first console login

## Security Best Practices

1. After Setup:
   - Store access keys securely
   - Update console password immediately
   - Configure MFA for console access
   - Review CloudTrail logs regularly

2. Ongoing Maintenance:
   - Regularly rotate access keys
   - Monitor AWS CloudTrail for unauthorized access
   - Review IAM policies periodically
   - Keep Terraform configurations in secure repository

## Notes
- Keep Terraform state secure as it contains sensitive outputs
- Regular security audits recommended