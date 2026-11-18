output "database" {
  value = module.environment.database
}

output "warehouse" {
  value = module.warehouse.name
}

output "roles" {
  value = {
    loader      = module.environment.loader_role
    transformer = module.environment.transformer_role
    raw_reader  = module.environment.raw_reader_role
    developer   = snowflake_account_role.developer.name
  }
}

output "local_dev" {
  description = "Values for the local-dev dbt profile (~/.dbt/profiles.yml)."
  value = {
    database  = snowflake_database.dev.name
    warehouse = module.dev_warehouse.name
    role      = snowflake_account_role.developer.name
  }
}
