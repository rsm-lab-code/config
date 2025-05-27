output "config_bucket_name" {
  description = "Name of the AWS Config S3 bucket"
  value       = aws_s3_bucket.config_bucket.bucket
}

output "config_recorder_name" {
  description = "Name of the AWS Config recorder"
  value       = aws_config_configuration_recorder.test_recorder.name
}

output "config_rule_name" {
  description = "Name of the test Config rule"
  value       = aws_config_config_rule.ssh_test.name
}
