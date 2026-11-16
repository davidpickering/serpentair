# One deployed environment's Snowflake objects: a database with RAW and ANALYTICS schemas,
# plus the roles that load, read and transform them. Used by infra/envs/prod (and qa in #10).
#
#   <ENV>_LOADER      writes RAW (Snowpipe, stages and raw tables arrive in #5)
#   <ENV>_RAW_READER  read-only on RAW. Prod's is how local-dev and qa read the gold record (ADR 0002)
#   <ENV>_TRANSFORMER dbt's role: reads RAW (via RAW_READER), builds in ANALYTICS
#
# Two providers, so each statement runs as the least-privileged system role that can do it:
#   snowflake               (SYSADMIN)      creates the database and schemas
#   snowflake.securityadmin (SECURITYADMIN) creates roles and grants privileges

terraform {
  required_providers {
    snowflake = {
      source                = "snowflakedb/snowflake"
      configuration_aliases = [snowflake.securityadmin]
    }
  }
}

locals {
  env    = upper(var.environment)
  prefix = "${local.env}_"
}

# --- Database and schemas (SYSADMIN) ---------------------------------------------------------

resource "snowflake_database" "this" {
  name    = "SERPENTAIR_${local.env}"
  comment = "serpentair ${var.environment}: RAW (landed source data) and ANALYTICS (dbt)."
}

resource "snowflake_schema" "raw" {
  database = snowflake_database.this.name
  name     = "RAW"
  comment  = var.raw_schema_comment
}

resource "snowflake_schema" "analytics" {
  database = snowflake_database.this.name
  name     = "ANALYTICS"
  comment  = "dbt builds here in ${var.environment}."
}

# --- Roles (SECURITYADMIN) -------------------------------------------------------------------

resource "snowflake_account_role" "loader" {
  provider = snowflake.securityadmin
  name     = "${local.prefix}LOADER"
  comment  = "Loads landed source files into ${snowflake_database.this.name}.RAW."
}

resource "snowflake_account_role" "raw_reader" {
  provider = snowflake.securityadmin
  name     = "${local.prefix}RAW_READER"
  comment  = "Read-only access to ${snowflake_database.this.name}.RAW."
}

resource "snowflake_account_role" "transformer" {
  provider = snowflake.securityadmin
  name     = "${local.prefix}TRANSFORMER"
  comment  = "dbt in ${var.environment}: reads RAW, builds ANALYTICS."
}

# Snowflake best practice: roll every custom role up to SYSADMIN, so the system admin role can
# still see and manage everything these roles create (dbt's tables, for example).
resource "snowflake_grant_account_role" "to_sysadmin" {
  provider = snowflake.securityadmin
  for_each = {
    loader      = snowflake_account_role.loader.name
    raw_reader  = snowflake_account_role.raw_reader.name
    transformer = snowflake_account_role.transformer.name
  }
  role_name        = each.value
  parent_role_name = "SYSADMIN"
}

# The transformer reads RAW by inheriting the reader role rather than holding its own grants.
resource "snowflake_grant_account_role" "raw_reader_to_transformer" {
  provider         = snowflake.securityadmin
  role_name        = snowflake_account_role.raw_reader.name
  parent_role_name = snowflake_account_role.transformer.name
}

# --- Privileges (SECURITYADMIN) --------------------------------------------------------------

resource "snowflake_grant_privileges_to_account_role" "database_usage" {
  provider = snowflake.securityadmin
  for_each = {
    loader      = snowflake_account_role.loader.name
    raw_reader  = snowflake_account_role.raw_reader.name
    transformer = snowflake_account_role.transformer.name
  }
  account_role_name = each.value
  privileges        = ["USAGE"]
  on_account_object {
    object_type = "DATABASE"
    object_name = snowflake_database.this.name
  }
}

# dbt may create extra schemas (custom schemas, e.g. ANALYTICS_STAGING) as the project grows.
resource "snowflake_grant_privileges_to_account_role" "transformer_create_schema" {
  provider          = snowflake.securityadmin
  account_role_name = snowflake_account_role.transformer.name
  privileges        = ["CREATE SCHEMA"]
  on_account_object {
    object_type = "DATABASE"
    object_name = snowflake_database.this.name
  }
}

resource "snowflake_grant_privileges_to_account_role" "warehouse_usage" {
  provider          = snowflake.securityadmin
  account_role_name = snowflake_account_role.transformer.name
  privileges        = ["USAGE"]
  on_account_object {
    object_type = "WAREHOUSE"
    object_name = var.warehouse_name
  }
}

# RAW: the loader creates loading objects and writes; the reader only reads.
resource "snowflake_grant_privileges_to_account_role" "loader_raw_schema" {
  provider          = snowflake.securityadmin
  account_role_name = snowflake_account_role.loader.name
  privileges        = ["USAGE", "CREATE TABLE", "CREATE STAGE", "CREATE FILE FORMAT", "CREATE PIPE"]
  on_schema {
    schema_name = snowflake_schema.raw.fully_qualified_name
  }
}

resource "snowflake_grant_privileges_to_account_role" "raw_reader_raw_schema" {
  provider          = snowflake.securityadmin
  account_role_name = snowflake_account_role.raw_reader.name
  privileges        = ["USAGE"]
  on_schema {
    schema_name = snowflake_schema.raw.fully_qualified_name
  }
}

# Future grants: tables created in RAW later (#5 onwards) get these privileges automatically.
resource "snowflake_grant_privileges_to_account_role" "loader_raw_future_tables" {
  provider          = snowflake.securityadmin
  account_role_name = snowflake_account_role.loader.name
  privileges        = ["SELECT", "INSERT"]
  on_schema_object {
    future {
      object_type_plural = "TABLES"
      in_schema          = snowflake_schema.raw.fully_qualified_name
    }
  }
}

resource "snowflake_grant_privileges_to_account_role" "raw_reader_future" {
  provider = snowflake.securityadmin
  for_each = toset(["TABLES", "VIEWS"])

  account_role_name = snowflake_account_role.raw_reader.name
  privileges        = ["SELECT"]
  on_schema_object {
    future {
      object_type_plural = each.key
      in_schema          = snowflake_schema.raw.fully_qualified_name
    }
  }
}

# ANALYTICS: the transformer builds tables and views (it owns whatever it creates).
resource "snowflake_grant_privileges_to_account_role" "transformer_analytics_schema" {
  provider          = snowflake.securityadmin
  account_role_name = snowflake_account_role.transformer.name
  privileges        = ["USAGE", "CREATE TABLE", "CREATE VIEW"]
  on_schema {
    schema_name = snowflake_schema.analytics.fully_qualified_name
  }
}
