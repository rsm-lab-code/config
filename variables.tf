variable "delegated_account_id" {
  description = "AWS Account ID for delegated account where Config will be created"
  type        = string
}

variable "management_account_id" {
  description = "AWS Account ID for management account where Config will be created"
  type        = string
}
