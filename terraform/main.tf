resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.location
  tags     = var.common_tags
}

resource "azurerm_service_plan" "asp" {
  name                = var.app_service_plan_name
  resource_group_name = azurerm_resource_group.rg.name
  location            = var.app_location
  os_type             = "Linux"
  sku_name            = "F1"
  tags                = var.common_tags
}

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
    delete_retention_policy { days = 7 }
    container_delete_retention_policy { days = 7 }
  }

  network_rules {
    default_action = "Allow"
    bypass         = ["AzureServices"]
  }

  tags = var.common_tags
}

resource "azurerm_storage_container" "uploads" {
  name                  = var.storage_container_name
  storage_account_id    = azurerm_storage_account.storage.id
  container_access_type = "private"
}

resource "azurerm_linux_web_app" "backend" {
  name                = var.backend_app_name
  resource_group_name = azurerm_resource_group.rg.name
  location            = var.app_location
  service_plan_id     = azurerm_service_plan.asp.id
  https_only          = true

  site_config {
    always_on        = false
    http2_enabled    = false
    app_command_line = "dotnet BackendApi.dll"
    application_stack { dotnet_version = "8.0" }
  }

  app_settings = {
    AZURE_STORAGE_CONNECTION_STRING = azurerm_storage_account.storage.primary_connection_string
    AZURE_STORAGE_CONTAINER_NAME    = azurerm_storage_container.uploads.name
  }

  tags       = var.common_tags
  depends_on = [azurerm_storage_container.uploads]
}

resource "azurerm_linux_web_app" "frontend" {
  name                = var.frontend_app_name
  resource_group_name = azurerm_resource_group.rg.name
  location            = var.app_location
  service_plan_id     = azurerm_service_plan.asp.id
  https_only          = true

  site_config {
    always_on        = false
    http2_enabled    = false
    app_command_line = "pm2 serve /home/site/wwwroot --no-daemon --spa"
    application_stack { node_version = "20-lts" }
  }

  app_settings = {
    WEBSITES_ENABLE_APP_SERVICE_STORAGE = "false"
  }

  tags = var.common_tags
}