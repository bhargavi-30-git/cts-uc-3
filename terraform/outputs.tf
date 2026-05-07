# =============================================================================
# outputs.tf — Values printed after successful terraform apply
# =============================================================================
# These show up in the terminal so you immediately know:
#   - Where to test the backend API
#   - Where to open the frontend
#   - Storage account name (for portal browsing)
# =============================================================================

output "frontend_url" {
  description = "Open this URL in browser to use the app"
  value       = "https://${azurerm_linux_web_app.frontend.default_hostname}"
}

output "backend_url" {
  description = "Backend API base URL"
  value       = "https://${azurerm_linux_web_app.backend.default_hostname}"
}

output "backend_api_test_url" {
  description = "Hit this in browser — should return [] before any uploads"
  value       = "https://${azurerm_linux_web_app.backend.default_hostname}/api/storage/list"
}

output "storage_account_name" {
  description = "Storage account holding the uploads container"
  value       = azurerm_storage_account.storage.name
}

output "resource_group_name" {
  description = "Resource group containing all UC3 resources"
  value       = azurerm_resource_group.rg.name
}
