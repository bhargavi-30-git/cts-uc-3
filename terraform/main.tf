terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
  required_version = ">= 1.3.0"

  backend "azurerm" {
    resource_group_name  = "uc5-state-rg"
    storage_account_name = "uc5tfstate234"
    container_name       = "tfstate-uc3"
    key                  = "uc3_infra.tfstate"
  }
}

provider "azurerm" {
  features {}
}

# ============================================================
# VARIABLES
# ============================================================

variable "resource_group_name" {
  default = "rg-uc3-tf"
}

variable "location" {
  default = "East Asia"
}

variable "frontend_app_name" {
  default = "tf-uc3-frontend"
}

variable "backend_app_name" {
  default = "tf-uc3-backend"
}

variable "storage_account_name" {
  default = "tfuc3storage001"
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
# APP SERVICE PLAN — F1 Free
# ============================================================

resource "azurerm_service_plan" "asp" {
  name                = var.app_service_plan_name
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  os_type             = "Linux"
  sku_name            = "F1"
}

# ============================================================
# FRONTEND — Node 20 LTS
# ============================================================

resource "azurerm_linux_web_app" "frontend" {
  name                = var.frontend_app_name
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  service_plan_id     = azurerm_service_plan.asp.id
  https_only          = true

  site_config {
    always_on        = false
    http2_enabled    = false
    app_command_line = "pm2 serve /home/site/wwwroot --no-daemon --spa"

    application_stack {
      node_version = "20-lts"
    }
  }

  app_settings = {
    WEBSITES_ENABLE_APP_SERVICE_STORAGE = "false"
  }
}

# ============================================================
# BACKEND — .NET 8
# ============================================================

resource "azurerm_linux_web_app" "backend" {
  name                = var.backend_app_name
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  service_plan_id     = azurerm_service_plan.asp.id
  https_only          = true

  site_config {
    always_on        = false
    http2_enabled    = false
    app_command_line = "dotnet BackendApi.dll"

    application_stack {
      dotnet_version = "8.0"
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
  name                            = var.storage_account_name
  resource_group_name             = azurerm_resource_group.rg.name
  location                        = azurerm_resource_group.rg.location
  account_tier                    = "Standard"
  account_replication_type        = "LRS"
  account_kind                    = "StorageV2"
  access_tier                     = "Hot"
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
# BLOB CONTAINER — uploads
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
  value = "https://${azurerm_linux_web_app.frontend.default_hostname}"
}

output "backend_url" {
  value = "https://${azurerm_linux_web_app.backend.default_hostname}"
}

output "backend_api_test_url" {
  value = "https://${azurerm_linux_web_app.backend.default_hostname}/api/storage/list"
}

output "storage_account_name" {
  value = azurerm_storage_account.storage.name
}

output "storage_container_name" {
  value = azurerm_storage_container.uploads.name
}