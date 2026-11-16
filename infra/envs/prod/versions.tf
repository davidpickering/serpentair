terraform {
  required_version = ">= 1.10"

  required_providers {
    snowflake = {
      source  = "snowflakedb/snowflake"
      version = "~> 2.23"
    }
  }

  # State lives in the bucket infra/bootstrap created; prod and qa each get their own key.
  # AWS credentials for the backend: the `serpentair` CLI profile locally (infra/tf.sh sets
  # AWS_PROFILE), the CI role in GitHub Actions (#9).
  backend "s3" {
    bucket       = "serpentair-terraform-state"
    key          = "envs/prod/terraform.tfstate"
    region       = "us-east-2"
    encrypt      = true
    use_lockfile = true
  }
}

# Runs as the CI service user (SVC_TERRAFORM_CI), locally via infra/tf.sh and in CI.
# One provider configuration per system role; each resource picks the least-powerful one
# that can do its job. The user's secondary roles are off, so these really are separate.

provider "snowflake" {
  role = "SYSADMIN" # databases, schemas
}

provider "snowflake" {
  alias = "securityadmin"
  role  = "SECURITYADMIN" # roles and grants
}

provider "snowflake" {
  alias = "accountadmin"
  role  = "ACCOUNTADMIN" # resource monitors, and attaching them to warehouses: nothing else
}
