variable "name" {
  description = "Warehouse name, e.g. PROD_WH."
  type        = string
}

variable "resource_monitor" {
  description = "Name of the resource monitor that suspends this warehouse at the credit quota."
  type        = string
}

variable "comment" {
  description = "What the warehouse is for."
  type        = string
  default     = null
}
