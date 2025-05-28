# Simple S3 bucket for AWS Config
resource "aws_s3_bucket" "config_bucket" {
  provider      = aws.management_account_us-west-2
  #provider      = aws.delegated_account_us-west-2
  bucket        = "aws-config-test-${var.management_account_id}"
  force_destroy = true

  tags = {
    Name = "aws-config-test-bucket"
  }
}

# Basic S3 bucket policy for AWS Config
resource "aws_s3_bucket_policy" "config_bucket_policy" {
  #provider = aws.delegated_account_us-west-2
  provider = aws.management_account_us-west-2
  bucket   = aws_s3_bucket.config_bucket.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "config.amazonaws.com"
        }
        Action = [
          "s3:GetBucketAcl",
          "s3:ListBucket",
          "s3:PutObject"
        ]
        Resource = [
          aws_s3_bucket.config_bucket.arn,
          "${aws_s3_bucket.config_bucket.arn}/*"
        ]
        Condition = {
          StringEquals = {
            "AWS:SourceAccount" = var.delegated_account_id
          }
        }
      }
    ]
  })
}

# IAM role for AWS Config
resource "aws_iam_role" "config_role" {
  #provider = aws.delegated_account_us-west-2
  provider      = aws.management_account_us-west-2
  name     = "aws-config-test-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "config.amazonaws.com"
        }
      }
    ]
  })
}

# Attach the AWS managed Config policy
resource "aws_iam_role_policy_attachment" "config_role_policy" {
  provider      = aws.management_account_us-west-2
  # provider   = aws.delegated_account_us-west-2
  role       = aws_iam_role.config_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWS_ConfigRole"
}

# AWS Config Configuration Recorder
resource "aws_config_configuration_recorder" "test_recorder" {
  # provider = aws.delegated_account_us-west-2
  provider      = aws.management_account_us-west-2
  name     = "test-recorder"
  role_arn = aws_iam_role.config_role.arn

  recording_group {
    all_supported = true
  }
}

# AWS Config Delivery Channel
resource "aws_config_delivery_channel" "test_channel" {
  #provider       = aws.delegated_account_us-west-2
  provider      = aws.management_account_us-west-2
  name           = "test-delivery-channel"
  s3_bucket_name = aws_s3_bucket.config_bucket.bucket
}

# Enable Config Recorder
resource "aws_config_configuration_recorder_status" "test_recorder_status" {
  #  provider   = aws.delegated_account_us-west-2
  provider      = aws.management_account_us-west-2
  name       = aws_config_configuration_recorder.test_recorder.name
  is_enabled = true
  depends_on = [aws_config_delivery_channel.test_channel]
}

#check if SSH is restricted
resource "aws_config_config_rule" "ssh_test" {
  # provider = aws.delegated_account_us-west-2
  provider      = aws.management_account_us-west-2
  name     = "ssh-restricted-test"

  source {
    owner             = "AWS"
    source_identifier = "INCOMING_SSH_DISABLED"
  }

  depends_on = [aws_config_configuration_recorder.test_recorder]
}


#check if account is part of AWS Organization
resource "aws_config_config_rule" "account_part_of_organization" {
  provider      = aws.management_account_us-west-2
  # provider = aws.delegated_account_us-west-2
  name     = "account-part-of-organization"

  source {
    owner             = "AWS"
    source_identifier = "ACCOUNT_PART_OF_ORGANIZATIONS"
  }

  depends_on = [aws_config_configuration_recorder.test_recorder]
}


#check if VPCs have Flow Logs enabled 
resource "aws_config_config_rule" "vpc_flow_logs_enabled" {
  provider      = aws.management_account_us-west-2
  #  provider = aws.delegated_account_us-west-2
  name     = "vpc-flow-logs-enabled-test"

  source {
    owner             = "AWS"
    source_identifier = "VPC_FLOW_LOGS_ENABLED"
  }

  depends_on = [aws_config_configuration_recorder.test_recorder]
}

#check if default security groups are closed 
resource "aws_config_config_rule" "vpc_default_sg_closed" {
  provider      = aws.management_account_us-west-2
  #  provider = aws.delegated_account_us-west-2
  name     = "vpc-default-sg-closed-test"

  source {
    owner             = "AWS"
    source_identifier = "VPC_DEFAULT_SECURITY_GROUP_CLOSED"
  }

  depends_on = [aws_config_configuration_recorder.test_recorder]
}
