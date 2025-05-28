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

output "organization_config_rule_names" {
  description = "Names of the organization Config rules"
  value = [
    aws_config_organization_managed_rule.ssh_test.name,
    aws_config_organization_managed_rule.account_part_of_organization.name,
    aws_config_organization_managed_rule.vpc_default_sg_closed.name,
    aws_config_organization_managed_rule.vpc_flow_logs_enabled.name
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