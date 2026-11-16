# Local-dev has no Terraform root of its own (only qa and prod are deployed), but a developer
# still needs somewhere to build. Prod provides it, because prod owns the gold record that
# local-dev reads.
#
#   SERPENTAIR_DEV  database where each developer's dbt builds a personal schema (dbt_<name>)
#   DEV_WH          the developer's own warehouse, on the same resource monitor as prod
#   DEVELOPER       role: build in SERPENTAIR_DEV, read the prod gold record, nothing else

resource "snowflake_database" "dev" {
  name    = "SERPENTAIR_DEV"
  comment = "Local-dev: personal dbt schemas (dbt_<name>). Disposable."

  # Transient: no Fail-safe (Snowflake's 7-day recovery copy), so throwaway dev builds don't
  # pay for extra storage. Fine, because everything here can be rebuilt from the gold record.
  is_transient = true
}

module "dev_warehouse" {
  source    = "../../modules/snowflake_warehouse"
  providers = { snowflake = snowflake.accountadmin }

  name             = "DEV_WH"
  comment          = "Local-dev dbt builds and ad hoc queries."
  resource_monitor = snowflake_resource_monitor.monthly.name
}

resource "snowflake_account_role" "developer" {
  provider = snowflake.securityadmin
  name     = "DEVELOPER"
  comment  = "Local-dev: builds personal schemas in SERPENTAIR_DEV and reads the prod gold record."
}

resource "snowflake_grant_account_role" "developer_to_sysadmin" {
  provider         = snowflake.securityadmin
  role_name        = snowflake_account_role.developer.name
  parent_role_name = "SYSADMIN"
}

# Read-only access to the gold record (ADR 0002): local-dev reads prod RAW but can't change it.
resource "snowflake_grant_account_role" "prod_raw_reader_to_developer" {
  provider         = snowflake.securityadmin
  role_name        = module.environment.raw_reader_role
  parent_role_name = snowflake_account_role.developer.name
}

resource "snowflake_grant_account_role" "developer_to_admin_user" {
  provider  = snowflake.securityadmin
  role_name = snowflake_account_role.developer.name
  user_name = var.snowflake_admin_user
}

# dbt creates the personal schema (dbt_<name>) itself on the first build.
resource "snowflake_grant_privileges_to_account_role" "developer_dev_database" {
  provider          = snowflake.securityadmin
  account_role_name = snowflake_account_role.developer.name
  privileges        = ["USAGE", "CREATE SCHEMA"]
  on_account_object {
    object_type = "DATABASE"
    object_name = snowflake_database.dev.name
  }
}

resource "snowflake_grant_privileges_to_account_role" "developer_dev_warehouse" {
  provider          = snowflake.securityadmin
  account_role_name = snowflake_account_role.developer.name
  privileges        = ["USAGE"]
  on_account_object {
    object_type = "WAREHOUSE"
    object_name = module.dev_warehouse.name
  }
}
