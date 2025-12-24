data "azurerm_resource_group" "main" {
  name = var.service_plan_resource_group_name
}

resource "azurerm_application_insights" "appinsights" {
  name                 = var.appinsights_name
  resource_group_name  = data.azurerm_resource_group.main.name
  location             = data.azurerm_resource_group.main.location
  workspace_id         = var.workspace_id
  application_type     = var.appinsights_application_type
  tags                 = var.resource_tags
  daily_data_cap_in_gb = var.appinsights_daily_data_cap_in_gb
}