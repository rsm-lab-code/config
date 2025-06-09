# MANAGEMENT ACCOUNT CONFIG RULES

# Basic security rules
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

resource "aws_config_config_rule" "tgw_auto_attach_disabled_mgmt" {
  provider = aws.management_account_us-west-2
  name     = "ec2-transit-gateway-auto-vpc-attach-disabled-mgmt"

  source {
    owner             = "AWS"
    source_identifier = "EC2_TRANSIT_GATEWAY_AUTO_VPC_ATTACH_DISABLED"
  }

  depends_on = [aws_config_configuration_recorder.test_recorder]
}

# ========================================
# MEMBER ACCOUNT CONFIG RULES
# ========================================

# Basic security rules for member account
resource "aws_config_config_rule" "member_ssh_test" {
  provider = aws.delegated_account_us-west-2
  name     = "ssh-restricted-member"

  source {
    owner             = "AWS"
g   source_identifier = "INCOMING_SSH_DISABLED"
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

resource "aws_config_config_rule" "subnet_auto_assign_public_ip_disabled" {
  provider = aws.delegated_account_us-west-2
  name     = "subnet-auto-assign-public-ip-disabled"

  source {
    owner             = "AWS"
    source_identifier = "SUBNET_AUTO_ASSIGN_PUBLIC_IP_DISABLED"
  }

  depends_on = [aws_config_configuration_recorder.member_recorder]
}

resource "aws_config_config_rule" "tgw_auto_attach_disabled_member" {
  provider = aws.delegated_account_us-west-2
  name     = "ec2-transit-gateway-auto-vpc-attach-disabled-member"

  source {
    owner             = "AWS"
    source_identifier = "EC2_TRANSIT_GATEWAY_AUTO_VPC_ATTACH_DISABLED"
  }

  depends_on = [aws_config_configuration_recorder.member_recorder]

