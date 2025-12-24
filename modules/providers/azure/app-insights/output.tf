output "app_insights_app_id" {
  description = "The App ID associated with this Application Insights component"
  value       = azurerm_application_insights.appinsights.app_id
}

output "app_insights_instrumentation_key" {
  description = "The Instrumentation Key for this Application Insights component."
  value       = azurerm_application_insights.appinsights.instrumentation_key
  sensitive   = true
}

output "app_insights_connection_string" {
  description = "The Connection String for this Application Insights component."
  value       = azurerm_application_insights.appinsights.connection_string
  sensitive   = true
}

output "app_insights_name" {
  description = "The name of the appinsights resource"
  value       = azurerm_application_insights.appinsights.name
}
