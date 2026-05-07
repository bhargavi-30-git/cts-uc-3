# =============================================================================
# variables.tf — Input Variables
# =============================================================================
# All configurable values live here. Defaults are pre-filled with Allen's
# preferred names, but each can be overridden in terraform.tfvars or via CLI.
# =============================================================================

variable "location" {
  description = "Azure region for all resources. Central India = lowest latency from Chennai."
  type        = string
  default     = "Central India"
}

variable "resource_group_name" {
  description = "Resource group that holds all UC3 application resources."
  type        = string
  default     = "rg-allen-uc3"
}

variable "app_service_plan_name" {
  description = "App Service Plan — both web apps share this plan to stay on F1 Free tier."
  type        = string
  default     = "asp-allen-uc3"
}

variable "frontend_app_name" {
  description = "Frontend Web App name. MUST be globally unique across all of Azure."
  type        = string
  default     = "allen-uc3-frontend-app"
}

variable "backend_app_name" {
  description = "Backend Web App name. MUST be globally unique across all of Azure."
  type        = string
  default     = "allen-uc3-backend-api"
}

variable "storage_account_name" {
  description = "Storage account for blob uploads. Lowercase only, 3-24 chars, no hyphens, globally unique."
  type        = string
  default     = "allenuc3appstor"
}

variable "storage_container_name" {
  description = "Blob container that holds uploaded files."
  type        = string
  default     = "uploads"
}

variable "common_tags" {
  description = "Tags applied to every resource for cost tracking & ownership."
  type        = map(string)
  default = {
    project     = "uc3-fullstackapp"
    owner       = "allen"
    environment = "dev"
    managed_by  = "terraform"
  }
}
