
variable "name" {
  description = "Name of Log Analystics Workspace."
  type        = string
}

variable "resource_group_name" {
  description = "The name of the resource group the resource will be created in"
  type        = string
}

variable "resource_tags" {
  description = "Map of tags to apply to taggable resources in this module. By default the taggable resources are tagged with the name defined above and this map is merged in"
  type        = map(string)
  default     = {}
}

variable "sku" {
  description = "Sku of the Log Analytics Workspace."
  type        = string
  default     = "PerGB2018"
}

variable "daily_quota_gb" {
  description = "(Optional) Specifies the Application Insights component daily data volume cap in GB."
  default     = 1000
}

variable "retention_in_days" {
  description = "The workspace data retention in days. Between 30 and 730."
  default     = 365
}

variable "security_center_subscription" {
  description = "List of subscriptions this log analytics should collect data for."
  type        = list(string)
  default     = []
}

variable "solutions" {
  description = "A list of solutions to add to the workspace."
  type        = list(object({ solution_name = string, publisher = string, product = string }))
  default     = []
}