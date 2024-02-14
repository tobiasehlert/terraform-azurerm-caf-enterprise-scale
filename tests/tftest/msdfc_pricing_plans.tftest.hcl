# run terraform init from module root,
# then run terraform test -test-directory=tests/tftest
#

variables {
  deploy_connectivity_resources = false
  archetype_config_overrides = {
    root = {
      archetype_id = "default_empty"
    }
    landing_zones = {
      archetype_id = "default_empty"
    }
    platform = {
      archetype_id = "default_empty"
    }
  }
  default_location             = "uksouth"
  root_parent_id               = "00000000-0000-0000-0000-000000000000"
  subscription_id_management   = "00000000-0000-0000-0000-000000000000"
  subscription_id_connectivity = "00000000-0000-0000-0000-000000000000"
  subscription_id_identity     = "00000000-0000-0000-0000-000000000000"
}

mock_provider "azurerm" {
  mock_data "azurerm_client_config" {
    defaults = {
      subscription_id = "00000000-0000-0000-0000-000000000000"
    }
  }
}

mock_provider "azurerm" {
  alias = "connectivity"
  mock_data "azurerm_client_config" {
    defaults = {
      subscription_id = "00000000-0000-0000-0000-000000000000"
    }
  }
}

mock_provider "azurerm" {
  alias = "management"
  mock_data "azurerm_client_config" {
    defaults = {
      subscription_id = "00000000-0000-0000-0000-000000000000"
    }
  }
}

run "msdfc_pricing_plan_single_sub" {
  command = plan

  assert {
    condition = keys(azapi_update_resource.defender_plans) == [
      "00000000-0000-0000-0000-000000000000_Api",
      "00000000-0000-0000-0000-000000000000_AppServices",
      "00000000-0000-0000-0000-000000000000_Arm",
      "00000000-0000-0000-0000-000000000000_Containers"
    ]
    error_message = "Expected 13 defender plans to be updated"
  }
}

run "msdfc_disabled" {
  comamnd = plan

  variables = {
    configure_management_resources = {
      settings = {
        security_center = {
          enabled = false
        }
      }
    }
  }

  assert {
    condition     = try(azapi_update_resource.defender_plans == null, true)
    error_message = "Expected no defender plans to be updated"

  }
}

# run "msdfc_pricing_plan_two_subs" {
#   command = plan

#   variables = {
#     subscription_id_connectivity = "00000000-0000-0000-0000-000000000001"
#   }

#   assert {
#     condition = keys(azapi_update_resource.defender_plans) == [
#       "00000000-0000-0000-0000-000000000000_enableAscForApis",
#       "00000000-0000-0000-0000-000000000000_enableAscForAppServices",
#       "00000000-0000-0000-0000-000000000000_enableAscForArm",
#       "00000000-0000-0000-0000-000000000000_enableAscForContainers"
#     ]
#     error_message = "Expected 13 defender plan to be updated"
#   }
# }
