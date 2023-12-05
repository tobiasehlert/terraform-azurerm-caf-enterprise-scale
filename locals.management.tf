# The following locals are used to build the map of Resource
# Groups to deploy.
locals {
  azurerm_resource_group_management = {
    for resource in module.management_resources.configuration.azurerm_resource_group :
    resource.resource_id => resource
    if resource.managed_by_module
  }
}

# The following locals are used to build the map of Log
# Analytics workspaces to deploy.
locals {
  azurerm_log_analytics_workspace_management = {
    for resource in module.management_resources.configuration.azurerm_log_analytics_workspace :
    resource.resource_id => resource
    if resource.managed_by_module
  }
}

# The following locals are used to build the map of Log
# Analytics workspaces to deploy.
locals {
  azurerm_log_analytics_solution_management = {
    for resource in module.management_resources.configuration.azurerm_log_analytics_solution :
    resource.resource_id => resource
    if resource.managed_by_module
  }
}

# The following locals are used to build the map of Log
# Analytics workspaces to deploy.
locals {
  azurerm_automation_account_management = {
    for resource in module.management_resources.configuration.azurerm_automation_account :
    resource.resource_id => resource
    if resource.managed_by_module
  }
}

# The following locals are used to build the map of Log
# Analytics workspaces to deploy.
locals {
  azurerm_log_analytics_linked_service_management = {
    for resource in module.management_resources.configuration.azurerm_log_analytics_linked_service :
    resource.resource_id => resource
    if resource.managed_by_module
  }
}

# The following locals are used to get the subscription id for each subscription
# and compare them to ensure that the subscription id for the management group
# is not the same as the identity or connectivity subscriptions.

locals {
  management_subscription_id   = var.subscription_id_management
  identity_subscription_id     = var.subscription_id_identity
  connectivity_subscription_id = var.subscription_id_connectivity
  comparison_result = (local.management_subscription_id == local.identity_subscription_id || local.management_subscription_id == local.connectivity_subscription_id) ? 0 : 1
}

#Advanced version of map to test for each logic from resources.management.tf
locals {
  map_defender_resource_types = {
    enableAscForApis                            = "Api"
    enableAscForAppServices                     = "AppServices"
    enableAscForArm                             = "Arm"
    enableAscForContainers                      = "Containers"
    enableAscForCosmosDbs                       = "CosmosDbs"
    enableAscForCspm                            = "CloudPosture"
    enableAscForDns                             = "Dns"
    enableAscForKeyVault                        = "KeyVaults"
    enableAscForOssDb                           = "OpenSourceRelationalDatabases"
    enableAscForServers                         = "VirtualMachines"
    # enableAscForServersVulnerabilityAssessments = "??"
    enableAscForSql                             = "SqlServers"
    enableAscForSqlOnVm                         = "SqlServerVirtualMachines"
    enableAscForStorage                         = "StorageAccounts"
  }
    
    azurerm_security_center_subscription_pricing = {
    for key, value in module.management_resources.configuration.archetype_config_overrides[var.root_id].parameters.Deploy-MDFC-Config :
    local.map_defender_resource_types[key] => value == "DeployIfNotExists" ? "Standard" : "Free"
    if startswith(key, "enable")
  }

}