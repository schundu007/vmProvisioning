variable "service_plan_resource_group_name" {
  description = "The name of the resource group in which the service plan was created."
  type        = string
}

variable "resource_tags" {
  description = "Map of tags to apply to taggable resources in this module"
  type        = map(string)
  default     = {}
}

variable "appinsights_name" {
  description = "Name of the App Insights to create"
  type        = string
}

variable "appinsights_application_type" {
  description = "Type of the App Insights Application."
  type        = string
}

variable "workspace_id" {
  description = "Specifies the id of a log analytics workspace resource."
  type        = string
  default     = "default"
}

variable "appinsights_daily_data_cap_in_gb" {
  description = "(Optional) Specifies the Application Insights component daily data volume cap in GB."
  type        = number
  default     = 100
}
