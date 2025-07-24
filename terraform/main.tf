terraform {
  required_version = ">= 1.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
}

provider "azurerm" {
  features {}
}

# Resource Group
resource "azurerm_resource_group" "main" {
  name     = var.resource_group_name
  location = var.location
  tags     = var.tags
}

# Storage Account for Static Web App (cheapest configuration)
resource "azurerm_storage_account" "static_web" {
  name                     = var.storage_account_name
  resource_group_name      = azurerm_resource_group.main.name
  location                 = azurerm_resource_group.main.location
  account_tier             = "Standard"
  account_replication_type = "LRS"  # Cheapest replication option
  account_kind             = "StorageV2"
  access_tier              = "Cool"  # Cheaper access tier for infrequent access
  
  static_website {
    index_document = "index.html"
    error_404_document = "404.html"
  }
  
  tags = var.tags
}

# App Service Plan
resource "azurerm_service_plan" "backend" {
  name                = var.app_service_plan_name
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  os_type             = "Linux"
  sku_name            = var.app_service_sku
  
  tags = var.tags
}

# App Service for Backend
resource "azurerm_linux_web_app" "backend" {
  name                = var.app_service_name
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  service_plan_id     = azurerm_service_plan.backend.id
  
  site_config {
    application_stack {
      node_version = "18"
    }
    
    application_settings = {
      "WEBSITE_NODE_DEFAULT_VERSION" = "~18"
      "NODE_ENV"                     = "production"
    }
  }
  
  app_settings = {
    "WEBSITE_RUN_FROM_PACKAGE" = "1"
  }
  
  tags = var.tags
}

# Static Web App for Frontend
resource "azurerm_static_site" "frontend" {
  name                = var.static_web_app_name
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  
  tags = var.tags
} 