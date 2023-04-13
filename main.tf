// Tags
locals {
  tags = {
    owner       = var.tag_department
    region      = var.tag_region
    environment = var.environment
  }
}

// Existing Resources

/// Subscription ID

data "azurerm_subscription" "current" {
}

// Random Suffix Generator

resource "random_integer" "deployment_id_suffix" {
  min = 100
  max = 999
}

// Resource Group

resource "azurerm_resource_group" "rg" {
  name     = "${var.class_name}-${var.student_name}-${var.environment}-${random_integer.deployment_id_suffix.result}-rg"
  location = var.location

  tags = local.tags
}


// Storage Account

resource "azurerm_storage_account" "storage" {
  name                     = "${var.student_name}${var.environment}${random_integer.deployment_id_suffix.result}st"
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"

  tags = local.tags
}



//Azure ML -- Khem

data "azurerm_client_config" "current" {}


resource "azurerm_application_insights" "appi" {
  name                = "${var.class_name}-${var.student_name}-${var.environment}-${random_integer.deployment_id_suffix.result}-appi"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  application_type    = "web"
}

resource "azurerm_key_vault" "kv" {
  name                = "${var.class_name}-${var.student_name}-${var.environment}-${random_integer.deployment_id_suffix.result}-kv"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  tenant_id           = data.azurerm_client_config.current.tenant_id
  sku_name            = "premium"
}



resource "azurerm_machine_learning_workspace" "mlw" {
  name                    = "${var.class_name}-${var.student_name}-${var.environment}-${random_integer.deployment_id_suffix.result}-mlw"
  location                = azurerm_resource_group.rg.location
  resource_group_name     = azurerm_resource_group.rg.name
  application_insights_id = azurerm_application_insights.appi.id
  key_vault_id            = azurerm_key_vault.kv.id
  storage_account_id      = azurerm_storage_account.storage.id

  identity {
    type = "SystemAssigned"
  }
}


// Cosmos DB -- Khem 

resource "random_integer" "ri" {
  min = 10000
  max = 99999
}

resource "azurerm_cosmosdb_account" "cdb" {
  name                = "tfex-cosmos-db-${random_integer.ri.result}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  offer_type          = "Standard"
  kind                = "MongoDB"

  enable_automatic_failover = true

  capabilities {
    name = "EnableAggregationPipeline"
  }

  capabilities {
    name = "mongoEnableDocLevelTTL"
  }

  capabilities {
    name = "MongoDBv3.4"
  }

  capabilities {
    name = "EnableMongo"
  }

  consistency_policy {
    consistency_level       = "BoundedStaleness"
    max_interval_in_seconds = 300
    max_staleness_prefix    = 100000
  }

  geo_location {
    location          = "eastus"
    failover_priority = 1
  }

  geo_location {
    location          = "westus"
    failover_priority = 0
  }
}

// Azure cognitive service -- Khem 

resource "azurerm_cognitive_account" "cs" {
  name                = "${var.class_name}-${var.student_name}-${var.environment}-${random_integer.deployment_id_suffix.result}-cs"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  kind                = "Face"
  sku_name            = "S0"
}


// Azure Synapse -- Khem 

resource "azurerm_storage_account" "gen2storage" {
  name                     = "${var.student_name}${var.environment}${random_integer.deployment_id_suffix.result}st2"
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  account_kind             = "StorageV2"
  is_hns_enabled           = "true"
}

resource "azurerm_storage_data_lake_gen2_filesystem" "gen2storage" {
  name               = "${var.student_name}-${var.environment}-${random_integer.deployment_id_suffix.result}-st2"
  storage_account_id = azurerm_storage_account.gen2storage.id

  properties = {
    hello = "aGVsbG8="
  }
}
resource "azurerm_synapse_workspace" "asw" {
  name                                 = "${var.class_name}-${var.student_name}-${var.environment}-${random_integer.deployment_id_suffix.result}-asw"
  resource_group_name                  = azurerm_resource_group.rg.name
  location                             = azurerm_resource_group.rg.location
  storage_data_lake_gen2_filesystem_id = azurerm_storage_data_lake_gen2_filesystem.gen2storage.id
  sql_administrator_login              = "sqladminuser"
  sql_administrator_login_password     = "H@Sh1CoR3!"


  identity {
    type = "SystemAssigned"
  }

  tags = {
    Env = "production"
  }
}
