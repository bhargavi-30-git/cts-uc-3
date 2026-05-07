# ============================================================
# Terraform — UC3 Full Stack Deployment
# Resources: Frontend App Service + Backend App Service + Blob Storage
# Region: Central India | All Free/Standard tier
# ============================================================

terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
  required_version = ">= 1.3.0"
}

provider "azurerm" {
  features {}
}

# ============================================================
# VARIABLES — change these for each new deployment
# ============================================================

variable "resource_group_name" {
  default = "rg-uc3-tf"
}

variable "location" {
  default = "Central India"
}

variable "frontend_app_name" {
  default = "tf-uc3-frontend"        # must be globally unique
}

variable "backend_app_name" {
  default = "tf-uc3-backend"         # must be globally unique
}

variable "storage_account_name" {
  default = "tfuc3storage001"        # lowercase, no hyphens, globally unique
}

variable "storage_container_name" {
  default = "uploads"
}

variable "app_service_plan_name" {
  default = "tf-uc3-asp"
}

# ============================================================
# RESOURCE GROUP
# ============================================================

resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.location
}

# ============================================================
# APP SERVICE PLAN — F1 Free tier (shared between both apps)
# ============================================================

resource "azurerm_service_plan" "asp" {
  name                = var.app_service_plan_name
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  os_type             = "Linux"
  sku_name            = "F1"
}

# ============================================================
# FRONTEND APP SERVICE — Node 24 LTS
# ============================================================

resource "azurerm_linux_web_app" "frontend" {
  name                = var.frontend_app_name
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  service_plan_id     = azurerm_service_plan.asp.id
  https_only          = true

  site_config {
    always_on     = false
    http2_enabled = false

    application_stack {
      node_version = "24-lts"
    }

    app_command_line = "pm2 serve /home/site/wwwroot --no-daemon --spa"

    ip_restriction {
      ip_address = "Any"
      action     = "Allow"
      priority   = 2147483647
      name       = "Allow all"
    }
  }

  app_settings = {
    WEBSITES_ENABLE_APP_SERVICE_STORAGE = "false"
  }
}

# ============================================================
# BACKEND APP SERVICE — .NET 8
# ============================================================

resource "azurerm_linux_web_app" "backend" {
  name                = var.backend_app_name
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  service_plan_id     = azurerm_service_plan.asp.id
  https_only          = true

  site_config {
    always_on     = false
    http2_enabled = false

    application_stack {
      dotnet_version = "8.0"
    }

    app_command_line = "dotnet BackendApi.dll"

    ip_restriction {
      ip_address = "Any"
      action     = "Allow"
      priority   = 2147483647
      name       = "Allow all"
    }
  }

  app_settings = {
    AZURE_STORAGE_CONNECTION_STRING = azurerm_storage_account.storage.primary_connection_string
    AZURE_STORAGE_CONTAINER_NAME    = var.storage_container_name
  }
}

# ============================================================
# STORAGE ACCOUNT — Standard LRS
# ============================================================

resource "azurerm_storage_account" "storage" {
  name                     = var.storage_account_name
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  account_kind             = "StorageV2"
  access_tier              = "Hot"

  min_tls_version                 = "TLS1_2"
  allow_nested_items_to_be_public = false
  https_traffic_only_enabled      = true

  blob_properties {
    delete_retention_policy {
      days = 7
    }
    container_delete_retention_policy {
      days = 7
    }
  }

  network_rules {
    default_action = "Allow"
    bypass         = ["AzureServices"]
  }
}

# ============================================================
# BLOB CONTAINER — uploads (private)
# ============================================================

resource "azurerm_storage_container" "uploads" {
  name                  = var.storage_container_name
  storage_account_name  = azurerm_storage_account.storage.name
  container_access_type = "private"
}

# ============================================================
# OUTPUTS
# ============================================================

output "frontend_url" {
  value       = "https://${azurerm_linux_web_app.frontend.default_hostname}"
  description = "Frontend App Service URL"
}

output "backend_url" {
  value       = "https://${azurerm_linux_web_app.backend.default_hostname}"
  description = "Backend App Service URL"
}

output "backend_api_test_url" {
  value       = "https://${azurerm_linux_web_app.backend.default_hostname}/api/storage/list"
  description = "Test URL — should return [] when backend is running"
}

output "storage_account_name" {
  value       = azurerm_storage_account.storage.name
}

output "storage_container_name" {
  value       = azurerm_storage_container.uploads.name
}