# =============================================================================
# backend.tf — Remote State Backend
# =============================================================================
# Stores the terraform.tfstate file in Allen's existing Azure Storage account
# (allendevopstfstate) inside the rg-tfstate resource group.
#
# Why remote state?
#   - Survives if local laptop dies / is reformatted
#   - Multiple people can collaborate (state locking via blob lease)
#   - Required for any production-grade Terraform workflow
#
# This block CANNOT use variables — backend config must be hardcoded.
# =============================================================================

terraform {
  required_version = ">= 1.3.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }

  backend "azurerm" {
    resource_group_name  = "rg-tfstate"
    storage_account_name = "allendevopstfstate"
    container_name       = "tfstate"
    key                  = "uc3.tfstate"
  }
}

provider "azurerm" {
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }
}
