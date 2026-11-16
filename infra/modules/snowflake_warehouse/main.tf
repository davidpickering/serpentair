# A Snowflake warehouse with the portfolio's cost rules baked in (ADR 0001). Callers choose a
# name and a resource monitor; they can't choose a size or turn off the guards, so every
# environment gets the same safeguards by construction.
#
# Must be called with an ACCOUNTADMIN provider: Snowflake only lets ACCOUNTADMIN attach a
# resource monitor to a warehouse.

terraform {
  required_providers {
    snowflake = {
      source = "snowflakedb/snowflake"
    }
  }
}

resource "snowflake_warehouse" "this" {
  name    = var.name
  comment = var.comment

  warehouse_size      = "XSMALL"
  auto_suspend        = 60   # seconds idle before suspending; Snowflake bills per second after the first minute
  auto_resume         = true # wakes on the next query, so a suspended warehouse costs nothing and needs no babysitting
  initially_suspended = true

  statement_timeout_in_seconds = 3600 # a runaway query is cancelled after one hour

  resource_monitor = var.resource_monitor
}
