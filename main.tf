# Create Organization-wide S3 bucket for AWS Config
resource "aws_s3_bucket" "config_bucket" {
  provider      = aws.management_account_us-west-2
  bucket        = "aws-config-org-${var.management_account_id}"
  force_destroy = true

  tags = {
    Name = "aws-config-organization-bucket"
  }
}

# S3 bucket versioning
resource "aws_s3_bucket_versioning" "config_bucket_versioning" {
  provider = aws.management_account_us-west-2
  bucket   = aws_s3_bucket.config_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}

# S3 bucket public access block
resource "aws_s3_bucket_public_access_block" "config_bucket_pab" {
  provider = aws.management_account_us-west-2
  bucket   = aws_s3_bucket.config_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Organization-wide S3 bucket policy for AWS Config
resource "aws_s3_bucket_policy" "config_bucket_policy" {
  provider = aws.management_account_us-west-2
  bucket   = aws_s3_bucket.config_bucket.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AWSConfigBucketPermissionsCheck"
        Effect = "Allow"
        Principal = {
          Service = "config.amazonaws.com"
        }
        Action   = "s3:GetBucketAcl"
        Resource = aws_s3_bucket.config_bucket.arn
        Condition = {
          StringEquals = {
            "AWS:SourceOrgID" = var.organization_id
          }
        }
      },
      {
        Sid    = "AWSConfigBucketExistenceCheck"
        Effect = "Allow"
        Principal = {
          Service = "config.amazonaws.com"
        }
        Action   = "s3:ListBucket"
        Resource = aws_s3_bucket.config_bucket.arn
        Condition = {
          StringEquals = {
            "AWS:SourceOrgID" = var.organization_id
          }
        }
      },
      {
        Sid    = "AWSConfigBucketDelivery"
        Effect = "Allow"
        Principal = {
          Service = "config.amazonaws.com"
        }
        Action   = "s3:PutObject"
        Resource = "${aws_s3_bucket.config_bucket.arn}/AWSLogs/*/Config/*"
        Condition = {
          StringEquals = {
            "s3:x-amz-acl" = "bucket-owner-full-control"
            "AWS:SourceOrgID" = var.organization_id
          }
        }
      },
      {
        Sid    = "AWSConfigBucketDeliveryCheck"
        Effect = "Allow"
        Principal = {
          Service = "config.amazonaws.com"
        }
        Action   = "s3:GetBucketAcl"
        Resource = aws_s3_bucket.config_bucket.arn
        Condition = {
          StringEquals = {
            "AWS:SourceOrgID" = var.organization_id
          }
        }
      }
    ]
  })
}

# Create IAM role for AWS Config in Management Account
resource "aws_iam_role" "config_role" {
  provider = aws.management_account_us-west-2
  name     = "aws-config-management-role"

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

# Attach the AWS managed Config policy to the role
resource "aws_iam_role_policy_attachment" "config_role_policy" {
  provider   = aws.management_account_us-west-2
  role       = aws_iam_role.config_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWS_ConfigRole" 
}

# IAM role for Config Organization access
resource "aws_iam_role" "config_organization_role" {
  provider = aws.management_account_us-west-2
  name     = "aws-config-organization-role"

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

# Attach organization policy to Config role
resource "aws_iam_role_policy_attachment" "config_organization_role_policy" {
  provider   = aws.management_account_us-west-2
  role       = aws_iam_role.config_organization_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWS_ConfigRole" 
}

# Additional organization permissions
resource "aws_iam_role_policy" "config_organization_policy" {
  provider = aws.management_account_us-west-2
  name     = "config-organization-policy"
  role     = aws_iam_role.config_organization_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "organizations:DescribeAccount",
          "organizations:DescribeOrganization",
          "organizations:ListAccounts",
          "organizations:ListAWSServiceAccessForOrganization"
        ]
        Resource = "*"
      }
    ]
  })
}

# AWS Config Configuration Recorder for Management Account (record changes in management account using the config_role)
resource "aws_config_configuration_recorder" "test_recorder" {
  provider = aws.management_account_us-west-2
  name     = "management-recorder"
  role_arn = aws_iam_role.config_role.arn

  recording_group {
    all_supported = true
  }
}

# AWS Config Delivery Channel for Management Account (where to deliver the configuration data)
resource "aws_config_delivery_channel" "test_channel" {
  provider       = aws.management_account_us-west-2
  name           = "management-delivery-channel"
  s3_bucket_name = aws_s3_bucket.config_bucket.bucket
}

# Enable Config Recorder for Management Account (enables change recorder)
resource "aws_config_configuration_recorder_status" "test_recorder_status" {
  provider   = aws.management_account_us-west-2
  name       = aws_config_configuration_recorder.test_recorder.name
  is_enabled = true
  depends_on = [aws_config_delivery_channel.test_channel]
}

# Config Aggregator for Organization (set up config aggregator to collect data across all AWS accounts)
resource "aws_config_configuration_aggregator" "organization_aggregator" {
  provider = aws.management_account_us-west-2
  name     = "organization-config-aggregator"

  organization_aggregation_source {
    all_regions = true
    role_arn    = aws_iam_role.config_organization_role.arn
  }

  depends_on = [aws_config_configuration_recorder.test_recorder]
}

# Regular Config Rules in Management Account 
resource "aws_config_config_rule" "ssh_test" {
  provider = aws.management_account_us-west-2
  name     = "ssh-restricted-mgmt"

  source {
    owner             = "AWS"
    source_identifier = "INCOMING_SSH_DISABLED"
  }

  depends_on = [aws_config_configuration_recorder.test_recorder]
}

resource "aws_config_config_rule" "account_part_of_organization" {
  provider = aws.management_account_us-west-2
  name     = "account-part-of-organization-mgmt"

  source {
    owner             = "AWS"
    source_identifier = "ACCOUNT_PART_OF_ORGANIZATIONS"
  }

  depends_on = [aws_config_configuration_recorder.test_recorder]
}

resource "aws_config_config_rule" "vpc_flow_logs_enabled" {
  provider = aws.management_account_us-west-2
  name     = "vpc-flow-logs-enabled-mgmt"

  source {
    owner             = "AWS"
    source_identifier = "VPC_FLOW_LOGS_ENABLED"
  }

  depends_on = [aws_config_configuration_recorder.test_recorder]
}

resource "aws_config_config_rule" "vpc_default_sg_closed" {
  provider = aws.management_account_us-west-2
  name     = "vpc-default-sg-closed-mgmt"

  source {
    owner             = "AWS"
    source_identifier = "VPC_DEFAULT_SECURITY_GROUP_CLOSED"
  }

  depends_on = [aws_config_configuration_recorder.test_recorder]
}

# IAM role for member account Config (create similar config role for non-management account)
resource "aws_iam_role" "member_config_role" {
  provider = aws.delegated_account_us-west-2
  name     = "aws-config-member-role"

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

resource "aws_iam_role_policy_attachment" "member_config_role_policy" {
  provider   = aws.delegated_account_us-west-2
  role       = aws_iam_role.member_config_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWS_ConfigRole"
}

# Member Account Config Recorder
resource "aws_config_configuration_recorder" "member_recorder" {
  provider = aws.delegated_account_us-west-2
  name     = "member-recorder"
  role_arn = aws_iam_role.member_config_role.arn

  recording_group {
    all_supported = true
  }
}

# Member Account Delivery Channel (points to management account S3)
resource "aws_config_delivery_channel" "member_channel" {
  provider       = aws.delegated_account_us-west-2
  name           = "member-delivery-channel"
  s3_bucket_name = aws_s3_bucket.config_bucket.bucket
}

# Enable Member Account Config Recorder
resource "aws_config_configuration_recorder_status" "member_recorder_status" {
  provider   = aws.delegated_account_us-west-2
  name       = aws_config_configuration_recorder.member_recorder.name
  is_enabled = true
  depends_on = [aws_config_delivery_channel.member_channel]
}

# Member Account Config Rules (same rules in delegated account)
resource "aws_config_config_rule" "member_ssh_test" {
  provider = aws.delegated_account_us-west-2
  name     = "ssh-restricted-member"

  source {
    owner             = "AWS"
    source_identifier = "INCOMING_SSH_DISABLED"
  }

  depends_on = [aws_config_configuration_recorder.member_recorder]
}

resource "aws_config_config_rule" "member_account_part_of_organization" {
  provider = aws.delegated_account_us-west-2
  name     = "account-part-of-organization-member"

  source {
    owner             = "AWS"
    source_identifier = "ACCOUNT_PART_OF_ORGANIZATIONS"
  }

  depends_on = [aws_config_configuration_recorder.member_recorder]
}

resource "aws_config_config_rule" "member_vpc_flow_logs_enabled" {
  provider = aws.delegated_account_us-west-2
  name     = "vpc-flow-logs-enabled-member"

  source {
    owner             = "AWS"
    source_identifier = "VPC_FLOW_LOGS_ENABLED"
  }

  depends_on = [aws_config_configuration_recorder.member_recorder]
}

resource "aws_config_config_rule" "member_vpc_default_sg_closed" {
  provider = aws.delegated_account_us-west-2
  name     = "vpc-default-sg-closed-member"

  source {
    owner             = "AWS"
    source_identifier = "VPC_DEFAULT_SECURITY_GROUP_CLOSED"
  }

  depends_on = [aws_config_configuration_recorder.member_recorder]
}