# CONFIG OUTPUTS
output "config_bucket_name" {
  description = "Name of the AWS Config S3 bucket"
  value       = aws_s3_bucket.config_bucket.bucket
}

output "management_config_recorder_name" {
  description = "Name of the AWS Config recorder in management account"
  value       = aws_config_configuration_recorder.test_recorder.name
}

output "member_config_recorder_name" {
  description = "Name of the AWS Config recorder in member account"
  value       = aws_config_configuration_recorder.member_recorder.name
}

output "management_config_rule_names" {
  description = "Names of the management account Config rules"
  value = [
    aws_config_config_rule.ssh_test.name,
    aws_config_config_rule.account_part_of_organization.name,
    aws_config_config_rule.vpc_default_sg_closed.name,
    aws_config_config_rule.vpc_flow_logs_enabled.name,
      ]
}

output "member_config_rule_names" {
  description = "Names of the member account Config rules"
  value = [
    aws_config_config_rule.member_ssh_test.name,
    aws_config_config_rule.member_account_part_of_organization.name,
    aws_config_config_rule.member_vpc_default_sg_closed.name,
    aws_config_config_rule.member_vpc_flow_logs_enabled.name,
    aws_config_config_rule.subnet_auto_assign_public_ip_disabled.name
  ]
}

output "config_aggregator_name" {
  description = "Name of the organization Config aggregator"
  value       = aws_config_configuration_aggregator.organization_aggregator.name
}

output "config_aggregator_arn" {
  description = "ARN of the organization Config aggregator"
  value       = aws_config_configuration_aggregator.organization_aggregator.arn
}

# ========================================
# NETWORK MANAGER OUTPUTS 
# ========================================

output "global_network_id" {
  description = "ID of the Global Network"
  value       = aws_networkmanager_global_network.main.id
}

output "global_network_arn" {
  description = "ARN of the Global Network"
  value       = aws_networkmanager_global_network.main.arn
}

output "transit_gateway_registration_id" {
  description = "ID of the Transit Gateway registration"
  value       = aws_networkmanager_transit_gateway_registration.main.id
}

output "network_manager_console_url" {
  description = "URL to access Network Manager console for this global network"
  value       = "https://${var.aws_regions[0]}.console.aws.amazon.com/networkmanager/networks/${aws_networkmanager_global_network.main.id}/global-networks"
}

output "config_console_url" {
  description = "URL to access Config dashboard"
  value       = "https://${var.aws_regions[0]}.console.aws.amazon.com/config/home?region=${var.aws_regions[0]}#/dashboard"
}

# ========================================
# COMBINED GOVERNANCE OUTPUTS 
# ========================================

output "governance_summary" {
  description = "Summary of governance components deployed"
  value = {
    config_enabled           = true
    network_manager_enabled  = true
    global_network_id       = aws_networkmanager_global_network.main.id
    config_aggregator       = aws_config_configuration_aggregator.organization_aggregator.name
    total_config_rules      = length(concat(
      [
        aws_config_config_rule.ssh_test.name,
        aws_config_config_rule.account_part_of_organization.name,
        aws_config_config_rule.vpc_default_sg_closed.name,
        aws_config_config_rule.vpc_flow_logs_enabled.name,      
        aws_config_config_rule.tgw_auto_attach_disabled_mgmt.name
      ],
      [
        aws_config_config_rule.member_ssh_test.name,
        aws_config_config_rule.member_account_part_of_organization.name,
        aws_config_config_rule.member_vpc_default_sg_closed.name,
        aws_config_config_rule.member_vpc_flow_logs_enabled.name,
        aws_config_config_rule.tgw_auto_attach_disabled_member.name,
        aws_config_config_rule.subnet_auto_assign_public_ip_disabled.name
      ]
    ))
    regions_covered         = var.aws_regions
  }
}
