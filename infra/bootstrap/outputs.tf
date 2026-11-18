output "state_bucket" {
  description = "S3 bucket holding Terraform state for every root."
  value       = aws_s3_bucket.terraform_state.bucket
}

output "snowflake_ci_user" {
  description = "Snowflake service user for the environment roots (SNOWFLAKE_CI_USER in .env)."
  value       = snowflake_service_user.terraform_ci.name
}
