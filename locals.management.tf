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

# local.map_defender_resource_types is creating a map of the DfC resource types and their subplans
# to be used by the below local, azurerm_security_center_subscription_pricing.
locals {
  map_defender_resource_types = {
    enableAscForApis                            = {
                                                    key = "Api"
                                                    subplan = "P1"
                                                  }
    enableAscForAppServices                     = {
                                                    key = "AppServices"
                                                    subplan = null
                                                  }
    enableAscForArm                             = {
                                                    key = "Arm"
                                                    subplan = "PerSubscription"
                                                  }
    enableAscForContainers                      = {
                                                    key = "Containers"
                                                    subplan = null
                                                  }
    enableAscForCosmosDbs                       = {
                                                    key = "CosmosDbs"
                                                    subplan = null
                                                  }
    enableAscForCspm                            = {
                                                    key = "CloudPosture"
                                                    subplan = null
                                                  }
    enableAscForDns                             = {
                                                    key = "Dns"
                                                    subplan = null
                                                  }
    enableAscForKeyVault                        = {
                                                    key = "KeyVaults"
                                                    subplan = "PerKeyVault"
                                                  }
    enableAscForOssDb                           = {
                                                    key = "OpenSourceRelationalDatabases"
                                                    subplan = null
                                                  }
    enableAscForServers                         = {
                                                    key = "VirtualMachines"
                                                    subplan = "P1"
                                                  }
    enableAscForSql                             = {
                                                    key = "SqlServers"
                                                    subplan = null
                                                  }
    enableAscForSqlOnVm                         = {
                                                    key = "SqlServerVirtualMachines"
                                                    subplan = null
                                                  }
    enableAscForStorage                         = {
                                                    key = "StorageAccounts"
                                                    subplan = "PerTransaction"
                                                  }
  }

# local.azurerm_security_center_subscription_pricing uses a loop to iterate over the configuration overrides and map the defender resource types to their respective pricing tiers.
# The tier is set to "Standard" if the value is "DeployIfNotExists", otherwise it is set to "Free".
# The subplan is set to the value of the "subplan" key in local.map_defender_resource_types, if the value is "DeployIfNotExists", otherwise it is set to null.
# The if condition filters on any keys that start with "enable" but are not equal to "enableAscForServersVulnerabilityAssessments".
  azurerm_security_center_subscription_pricing = {
    for key, value in module.management_resources.configuration.archetype_config_overrides[var.root_id].parameters.Deploy-MDFC-Config :
    local.map_defender_resource_types[key].key => {
      tier = value == "DeployIfNotExists" ? "Standard" : "Free"
      subplan = value == "DeployIfNotExists" ? lookup(local.map_defender_resource_types[key], "subplan",null) : null
    }
    if startswith(key, "enable") && key != "enableAscForServersVulnerabilityAssessments"
  }

# local.alz_subscriptions defines the list of platform subscription IDs for management, connectivity, and identity.
# The compact function is used to filter out any nill or empty strings values.
  alz_subscriptions = compact([ var.subscription_id_management, var.subscription_id_connectivity, var.subscription_id_identity ])

# local.distinct_azurerm_security_center_subscription_pricing is a map using a nested for loop to iterate over the local.alz_subscriptions list and the local.azurerm_security_center_subscription_pricing map.
# For each subscription ID in local.alz_subscriptions, a new map is created with the following attributes:
# The flatten function is used to flatten the list of maps into a single list of maps.
# The distinct function is used to remove any duplicate maps, i.e. potential duplicate subscription IDs.
# - composite_key: A combination of the subscription ID and the key from local.azurerm_security_center_subscription_pricing.
# - subscription_id: The subscription ID.
# - defender_plan_key: The key from local.azurerm_security_center_subscription_pricing.
# - defender_plan_tier: The tier value from local.azurerm_security_center_subscription_pricing.
# - defender_plan_subplan: The subplan value from local.azurerm_security_center_subscription_pricing.
# The resulting map is used by resources.management.tf to create the azapi_update_resource.defender_plans resources.
  distinct_azurerm_security_center_subscription_pricing = { for flattened_value in distinct(flatten([
      for subscription_id in local.alz_subscriptions : [
        for key, value in local.azurerm_security_center_subscription_pricing : [{
            composite_key = "${subscription_id}_${key}"
            subscription_id = subscription_id
            defender_plan_key = key
            defender_plan_tier = value.tier
            defender_plan_subplan = value.subplan
        }]
      ]
    ])) : flattened_value.composite_key => flattened_value
  }
}