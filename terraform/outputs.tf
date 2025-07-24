output "resource_group_name" {
  description = "Name of the created resource group"
  value       = azurerm_resource_group.main.name
}

output "resource_group_location" {
  description = "Location of the created resource group"
  value       = azurerm_resource_group.main.location
}

output "storage_account_name" {
  description = "Name of the storage account"
  value       = azurerm_storage_account.static_web.name
}

output "storage_account_primary_web_host" {
  description = "Primary web host of the storage account"
  value       = azurerm_storage_account.static_web.primary_web_host
}

output "app_service_name" {
  description = "Name of the App Service"
  value       = azurerm_linux_web_app.backend.name
}

output "app_service_url" {
  description = "URL of the App Service"
  value       = azurerm_linux_web_app.backend.default_hostname
}

output "static_web_app_name" {
  description = "Name of the Static Web App"
  value       = azurerm_static_site.frontend.name
}

output "static_web_app_url" {
  description = "URL of the Static Web App"
  value       = azurerm_static_site.frontend.default_host_name
}

output "static_web_app_api_key" {
  description = "API key for the Static Web App"
  value       = azurerm_static_site.frontend.api_key
  sensitive   = true
} 