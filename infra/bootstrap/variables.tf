variable "ci_user_name" {
  description = "Name of the Snowflake service user that runs the environment roots."
  type        = string
  default     = "SVC_TERRAFORM_CI"
}

variable "ci_public_key_path" {
  description = "PEM public key for the CI user. Public keys are safe to commit; the private key is not."
  type        = string
  default     = "keys/svc_terraform_ci.pub"
}
