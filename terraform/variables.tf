variable "location" {
  description = "Default region — used for Resource Group and Storage."
  type        = string
  default     = "Central India"
}

variable "app_location" {
  description = "Region for App Service Plan + Web Apps. Separate because free F1 isn't allowed in Central India for free-trial subs."
  type        = string
  default     = "Southeast Asia"
}

variable "resource_group_name" {
  type    = string
  default = "rg-allen-uc3"
}

variable "app_service_plan_name" {
  type    = string
  default = "asp-allen-uc3"
}

variable "frontend_app_name" {
  type    = string
  default = "allen-uc3-frontend-app"
}

variable "backend_app_name" {
  type    = string
  default = "allen-uc3-backend-api"
}

variable "storage_account_name" {
  type    = string
  default = "allenuc3appstor"
}

variable "storage_container_name" {
  type    = string
  default = "uploads"
}

variable "common_tags" {
  type = map(string)
  default = {
    project     = "uc3-fullstackapp"
    owner       = "allen"
    environment = "dev"
    managed_by  = "terraform"
  }
}