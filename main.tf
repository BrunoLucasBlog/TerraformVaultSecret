
#choose a resource prefix name
locals {
  resource_prefix_name = "TFormApr0622"  
}


# We strongly recommend using the required_providers block to set the
# Azure Provider source and version being used
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=2.46.0"
    }
  }
}

# Configure the Microsoft Azure Provider
provider "azurerm" {
  features {
    key_vault {
      purge_soft_delete_on_destroy = true
    }
  }

#create a service principal and pass the infor here - those are examples
  subscription_id = "fba123f4-00a1-4e63-a33c-0927d1abc0ce"
  client_id       = "6744449-8d0a-4aef-be05-e8564b78ca2"
  client_secret   = "gGb73456pTGMhgkFMLbRYa0zQ4560ZhaS"
  tenant_id       = "14cf8564-0c0f-493d-8e9b-1c665bc57de"
}

resource "azurerm_resource_group" "example" {
  name     = local.resource_prefix_name
  location = "West Europe"
}


resource "azurerm_app_service_plan" "example" {
  name                = "${local.resource_prefix_name}-appserviceplan"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name

  sku {
    tier = "Standard"
    size = "S1"
  }
}

data "azurerm_client_config" "current" {}

resource "azurerm_key_vault" "myproject-vault-main" {
  name                = "${local.resource_prefix_name}-vault-dev"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
  tenant_id           = data.azurerm_client_config.current.tenant_id
  sku_name            = "premium"
}

resource "azurerm_key_vault_access_policy" "access_policy_example" {
  key_vault_id = azurerm_key_vault.myproject-vault-main.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = data.azurerm_client_config.current.object_id

  key_permissions = [
    "Get"
  ]

  secret_permissions = [
    "Get","Set","List","Delete"
  ]
}

#storage is more restrictive on naming conventions - remember to change
resource "azurerm_storage_account" "myproject_storage" {
  name                     = "myprojectstoragedev02"
  resource_group_name      = azurerm_resource_group.example.name
  location                 = azurerm_resource_group.example.location
  account_tier             = "Standard"
  account_replication_type = "GRS"

  tags = {
    environment = "staging"
  }
}

resource "azurerm_key_vault_secret" "myproject-key_vault_secret" {
  name         = "storage-secret"
  value        = azurerm_storage_account.myproject_storage.primary_access_key
  key_vault_id = azurerm_key_vault.myproject-vault-main.id
}

