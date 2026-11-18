output "database" {
  value = snowflake_database.this.name
}

output "raw_schema" {
  value = snowflake_schema.raw.fully_qualified_name
}

output "analytics_schema" {
  value = snowflake_schema.analytics.fully_qualified_name
}

output "loader_role" {
  value = snowflake_account_role.loader.name
}

output "raw_reader_role" {
  description = "Grant this to another role to give it read-only access to this environment's RAW."
  value       = snowflake_account_role.raw_reader.name
}

output "transformer_role" {
  value = snowflake_account_role.transformer.name
}
