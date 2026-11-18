variable "environment" {
  description = "Environment name: prod or qa. Becomes the database suffix and role prefix."
  type        = string

  validation {
    condition     = contains(["prod", "qa"], var.environment)
    error_message = "environment must be prod or qa (local-dev has no Terraform root)."
  }
}

variable "warehouse_name" {
  description = "Warehouse the transformer role runs on (from the snowflake_warehouse module)."
  type        = string
}

variable "raw_schema_comment" {
  description = "Describes the RAW schema: the gold record in prod, a disposable smoke-run area in qa."
  type        = string
}
