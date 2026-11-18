# Prod: the only environment with scheduled, automated activity. Its RAW schema holds the
# gold record: the only authoritative copy of source data, read by dbt in every environment
# (ADR 0002).

module "warehouse" {
  source    = "../../modules/snowflake_warehouse"
  providers = { snowflake = snowflake.accountadmin }

  name             = "PROD_WH"
  comment          = "Prod dbt builds (CI deploys and the dbt platform daily job)."
  resource_monitor = snowflake_resource_monitor.monthly.name
}

module "environment" {
  source = "../../modules/snowflake_environment"
  providers = {
    snowflake               = snowflake
    snowflake.securityadmin = snowflake.securityadmin
  }

  environment        = "prod"
  warehouse_name     = module.warehouse.name
  raw_schema_comment = "The gold record: landed source data, loaded only in prod (ADR 0002)."
}
