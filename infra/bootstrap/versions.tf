terraform {
  required_version = ">= 1.10" # S3 native state locking (use_lockfile) needs 1.10+

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.73"
    }
    snowflake = {
      source  = "snowflakedb/snowflake"
      version = "~> 2.23"
    }
  }

  # Chicken-and-egg: this root creates the state bucket, so its first apply uses local state
  # (via a temporary backend_override.tf), then `terraform init -migrate-state` moves the
  # state into the bucket it just made. See infra/README.md.
  backend "s3" {
    bucket       = "serpentair-terraform-state"
    key          = "bootstrap/terraform.tfstate"
    region       = "us-east-2"
    encrypt      = true
    use_lockfile = true
  }
}

provider "aws" {
  region = "us-east-2" # the project's only selected Region (docs/agents/aws.md)

  default_tags {
    tags = {
      project    = "serpentair"
      managed_by = "terraform"
      root       = "bootstrap"
    }
  }
}

# Runs as the human admin (infra/tf.sh sets SNOWFLAKE_USER and the key from .env).
provider "snowflake" {
  role = "ACCOUNTADMIN"
}
