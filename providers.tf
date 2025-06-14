terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.49.0"
      configuration_aliases = [
        aws.delegated_account_us-west-2,
        aws.management_account_us-west-2
      ]
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.1"
    }
  }
}
