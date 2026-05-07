# =============================================================================
# main.tf — Core Infrastructure
# =============================================================================
# Builds the entire UC3 stack in ONE terraform apply:
#
#   Resource Group
#       │
#       ├─ App Service Plan (F1 Free, Linux)
#       │       │
#       │       ├─ Frontend Web App (Node 24 LTS, serves static HTML)
#       │       │   └─ Startup command: pm2 serve
#       │       │
#       │       └─ Backend Web App (.NET 8, REST API)
#       │           └─ Env vars: AZURE_STORAGE_CONNECTION_STRING + container name
#       │              (auto-wired from storage account below — no portal clicks)
#       │
#       └─ Storage Account (StorageV2, LRS, private)
#               └─ Blob Container "uploads" (private)
#
# Cost estimate: < $0.02 per month (F1 is free, storage is per-GB-pennies)
# =============================================================================


# -----------------------------------------------------------------------------
# Resource Group — container for all resources in this project
# -----------------------------------------------------------------------------
resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.location
  tags     = var.common_tags
}


# -----------------------------------------------------------------------------
# App Service Plan — F1 Free tier, Linux
# Both web apps share this single plan (allowed under F1 limits)
# -----------------------------------------------------------------------------
resource "azurerm_service_plan" "asp" {
  name                = var.app_service_plan_name
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  os_type             = "Linux"
  sku_name            = "F1"
  tags                = var.common_tags
}


# -----------------------------------------------------------------------------
# Storage Account — holds uploaded files in the "uploads" container
# -----------------------------------------------------------------------------
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

  tags = var.common_tags
}


# -----------------------------------------------------------------------------
# Blob Container — "uploads" — private (backend writes via SDK only)
# -----------------------------------------------------------------------------
resource "azurerm_storage_container" "uploads" {
  name                  = var.storage_container_name
  storage_account_id    = azurerm_storage_account.storage.id
  container_access_type = "private"
}


# -----------------------------------------------------------------------------
# Backend Web App — .NET 8 API
# Auto-wires the storage connection string into env vars (no portal clicks!)
# -----------------------------------------------------------------------------
resource "azurerm_linux_web_app" "backend" {
  name                = var.backend_app_name
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  service_plan_id     = azurerm_service_plan.asp.id
  https_only          = true

  site_config {
    always_on        = false # F1 tier doesn't support always_on
    http2_enabled    = false
    app_command_line = "dotnet BackendApi.dll"

    application_stack {
      dotnet_version = "8.0"
    }
  }

  app_settings = {
    AZURE_STORAGE_CONNECTION_STRING = azurerm_storage_account.storage.primary_connection_string
    AZURE_STORAGE_CONTAINER_NAME    = azurerm_storage_container.uploads.name
  }

  tags = var.common_tags

  # Make sure storage exists before backend tries to wire its connection string
  depends_on = [azurerm_storage_container.uploads]
}


# -----------------------------------------------------------------------------
# Frontend Web App — Node 24 LTS, serves static HTML via pm2
# -----------------------------------------------------------------------------
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

  tags = var.common_tags
}
