variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
  default     = "ahora-caigo-rg"
}

variable "location" {
  description = "Azure region for resources"
  type        = string
  default     = "East US"
}

variable "storage_account_name" {
  description = "Name of the storage account for static web hosting"
  type        = string
  default     = "ahoracaigostorage"
  
  validation {
    condition     = can(regex("^[a-z0-9]{3,24}$", var.storage_account_name))
    error_message = "Storage account name must be between 3 and 24 characters long and contain only lowercase letters and numbers."
  }
}

variable "app_service_plan_name" {
  description = "Name of the App Service Plan"
  type        = string
  default     = "ahora-caigo-app-plan"
}

variable "app_service_name" {
  description = "Name of the App Service for backend"
  type        = string
  default     = "ahora-caigo-backend"
  
  validation {
    condition     = can(regex("^[a-zA-Z0-9-]{1,60}$", var.app_service_name))
    error_message = "App Service name must be between 1 and 60 characters and contain only letters, numbers, and hyphens."
  }
}

variable "static_web_app_name" {
  description = "Name of the Static Web App for frontend"
  type        = string
  default     = "ahora-caigo-frontend"
  
  validation {
    condition     = can(regex("^[a-zA-Z0-9-]{1,60}$", var.static_web_app_name))
    error_message = "Static Web App name must be between 1 and 60 characters and contain only letters, numbers, and hyphens."
  }
}

variable "app_service_sku" {
  description = "SKU for the App Service Plan (F1 is free tier, B1 is cheapest paid tier)"
  type        = string
  default     = "F1"
  
  validation {
    condition     = contains(["F1", "B1", "B2", "B3", "S1", "S2", "S3", "P1V2", "P2V2", "P3V2"], var.app_service_sku)
    error_message = "App Service Plan SKU must be one of: F1, B1, B2, B3, S1, S2, S3, P1V2, P2V2, P3V2."
  }
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default = {
    Environment = "Production"
    Project     = "Ahora Caigo"
    ManagedBy   = "Terraform"
  }
} 