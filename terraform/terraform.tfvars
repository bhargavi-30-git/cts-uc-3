# =============================================================================
# terraform.tfvars — Allen's actual values
# =============================================================================
# Right now this file matches all the defaults in variables.tf — but it exists
# so you can easily tweak any name without touching variables.tf.
#
# To change a name later: edit the value here, then run `terraform apply` again.
# =============================================================================

location               = "Central India"
resource_group_name    = "rg-allen-uc3"
app_service_plan_name  = "asp-allen-uc3"
frontend_app_name      = "allen-uc3-frontend-app"
backend_app_name       = "allen-uc3-backend-api"
storage_account_name   = "allenuc3appstor"
storage_container_name = "uploads"
