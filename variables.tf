# ========================================
# SHARED VARIABLES (Config + Network Manager)
# ========================================

variable "aws_regions" {
  description = "List of AWS regions for deploying resources"
  type        = list(string)
  default     = ["us-west-2", "us-east-1"]
}

variable "delegated_account_id" {
  description = "AWS Account ID for delegated account where Config and Network Manager will be created"
  type        = string
}

variable "management_account_id" {
  description = "AWS Account ID for management account where Config will be created"
  type        = string
}

variable "organization_id" {
  description = "AWS Organization ID for Config organization setup"
  type        = string
}

# ========================================
# NETWORK MANAGER SPECIFIC VARIABLES 
# ========================================

variable "transit_gateway_arn" {
  description = "ARN of the Transit Gateway to register with Network Manager"
  type        = string
}

variable "global_network_description" {
  description = "Description for the global network"
  type        = string
  default     = "Global network for hub-and-spoke architecture"
}

variable "common_tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default = {
    ManagedBy = "terraform"
  }
}