variable "snowflake_admin_user" {
  description = "The human admin's Snowflake user: gets the DEVELOPER role and the monitor's emails. Set as TF_VAR_snowflake_admin_user (infra/tf.sh reads SNOWFLAKE_ADMIN_USER from .env)."
  type        = string
}

variable "monthly_credit_quota" {
  description = "Credits per calendar month across all Terraform-managed warehouses ($2.00/credit, Standard, AWS US East (Ohio))."
  type        = number
  default     = 6
}
