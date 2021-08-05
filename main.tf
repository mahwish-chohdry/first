
terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
    }
  }
}

provider "azurerm" {
    features {}
  # Configuration options
}

resource "azurerm_resource_group" "RGroup" {
  name     = "SmartFanTerraform"
  location = "West US"
}

resource "azurerm_eventhub_namespace" "EHName" {
  name                = "EventHubTerraform"
  location            = azurerm_resource_group.RGroup.location
  resource_group_name = azurerm_resource_group.RGroup.name
  sku                 = "Basic"
  capacity            = 1

}

resource "azurerm_eventhub" "EventHub" {
  name                = "InstanceTerraform"
  namespace_name      = azurerm_eventhub_namespace.EHName.name
  resource_group_name = azurerm_resource_group.RGroup.name
  partition_count     = 2
  message_retention   = 1
}
resource "azurerm_eventhub_authorization_rule" "EHAuth" {
  resource_group_name = azurerm_resource_group.RGroup.name
  namespace_name      = azurerm_eventhub_namespace.EHName.name
  eventhub_name       = azurerm_eventhub.EventHub.name
  name                = "acctest"
  send                = true
}

resource "azurerm_iothub" "IoTHub" {
  name                = "IoTHubTerraform"
  resource_group_name = azurerm_resource_group.RGroup.name
  location            = azurerm_resource_group.RGroup.location

sku {
    name     = "F1"
    capacity = "1"
  }
endpoint {
    type              = "AzureIotHub.EventHub"
    connection_string = azurerm_eventhub_authorization_rule.EHAuth.primary_connection_string
    name              = "IOT-EventEndpoint"
  }

route {
    name           = "IOT-EventEndpoint"
    source         = "DeviceMessages"
    condition      = "true"
    endpoint_names = ["IOT-EventEndpoint"]
    enabled        = true
  }
  }

  resource "azurerm_storage_account" "storage" {
  name                     = "storageterraformsf"
  resource_group_name      = azurerm_resource_group.RGroup.name
  location                 = azurerm_resource_group.RGroup.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
    allow_blob_public_access  = true


}

resource "azurerm_storage_container" "blob" {
  name                  = "firmware"
  storage_account_name  = azurerm_storage_account.storage.name
  container_access_type = "blob"
}

resource "azurerm_sql_server" "sql01" {
  name                         = "sqlserverterraform"
  resource_group_name          = azurerm_resource_group.RGroup.name
  location                     =  azurerm_resource_group.RGroup.location
  version                      = "12.0"
  administrator_login          = "Mahwish"
  administrator_login_password = "Banana1234567"
}
 
resource "azurerm_sql_firewall_rule" "allowAzureServices" {
  name                = "Allow_Azure_Services"
  resource_group_name = azurerm_sql_server.sql01.resource_group_name
  server_name         = azurerm_sql_server.sql01.name
  start_ip_address    = "0.0.0.0"
  end_ip_address      = "0.0.0.0"

}

resource "azurerm_sql_database" "db01" {
  depends_on                       = [azurerm_sql_firewall_rule.allowAzureServices]
  name                             = "SQLDBterraform"
  resource_group_name              = azurerm_sql_server.sql01.resource_group_name
  location                         = azurerm_sql_server.sql01.location
  server_name                      = azurerm_sql_server.sql01.name
  create_mode = "Default"

  import {
    storage_uri                  =  "https://storagetestingsf.blob.core.windows.net/dbbackup/smartfan-fresh.bacpac"
    storage_key                  =  "QpUb/DWG7wZp+cGkJjJMwjdypcUPpMACjXno6OSU4hnA4Ku6MVjPP/G4JV/LQvV3hkWDJ2wRBFZrSw9C7q7cEA=="
    storage_key_type             = "StorageAccessKey"
    administrator_login          = azurerm_sql_server.sql01.administrator_login
    administrator_login_password          = azurerm_sql_server.sql01.administrator_login_password
    authentication_type          =  "SQL"
    operation_mode               = "Import"
  }

}

  resource "azurerm_app_service_plan" "ApiPlan" {
  name                = "ASP_APITerraform"
  location            = azurerm_resource_group.RGroup.location
  resource_group_name = azurerm_resource_group.RGroup.name
  kind        = "Windows"
  sku {
    tier = "Basic"
    size = "B1"
  }
}
 resource "azurerm_application_insights" "AppInsightAPI" {
  name                = "AppInsightforAPI"
  location            = azurerm_resource_group.RGroup.location
  resource_group_name = azurerm_resource_group.RGroup.name
  application_type    = "web"
} 
resource "azurerm_app_service" "APIapp" {
  name                = "APIappTerraform"
  location            = azurerm_resource_group.RGroup.location
  resource_group_name = azurerm_resource_group.RGroup.name
  app_service_plan_id = azurerm_app_service_plan.ApiPlan.id


  site_config {
    dotnet_framework_version = "v4.0"
  }
  app_settings = {
    "APPINSIGHTS_INSTRUMENTATIONKEY" = azurerm_application_insights.AppInsightAPI.instrumentation_key
  }
  }

  resource "azurerm_app_service_plan" "PortalPlan" {
  name                = "APS-PortalTerraform"
  location            = azurerm_resource_group.RGroup.location
  resource_group_name = azurerm_resource_group.RGroup.name
  kind        = "Windows"
  sku {
    tier = "Basic"
    size = "B1"
  }
}
  resource "azurerm_application_insights" "AppInsight" {
  name                = "AppInsightforportal"
  location            = azurerm_resource_group.RGroup.location
  resource_group_name = azurerm_resource_group.RGroup.name
  application_type    = "web"
} 


resource "azurerm_app_service" "PortalApp" {
  name                = "PortalTerraform"
  location            = azurerm_resource_group.RGroup.location
  resource_group_name = azurerm_resource_group.RGroup.name
  app_service_plan_id = azurerm_app_service_plan.PortalPlan.id

 
  app_settings = {
    "APPINSIGHTS_INSTRUMENTATIONKEY" = azurerm_application_insights.AppInsight.instrumentation_key
  }
  site_config {
    dotnet_framework_version = "v4.0"
  }
 
 }


resource "azurerm_storage_account" "SAfunction" {
  name                     = "storageterraformfan"
  resource_group_name      = azurerm_resource_group.RGroup.name
  location                 = azurerm_resource_group.RGroup.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_app_service_plan" "ASPfun" {
  name                = "ASP-FunctionAppTerraform"
  location            = azurerm_resource_group.RGroup.location
  resource_group_name = azurerm_resource_group.RGroup.name
 kind      = "Windows"
  sku {
    tier = "Free"
    size = "F1"
  }
}
 resource "azurerm_application_insights" "AppInsightFunctionApp" {
  name                = "AppInsightforFunctionApp"
  location            = azurerm_resource_group.RGroup.location
  resource_group_name = azurerm_resource_group.RGroup.name
  application_type    = "web"
} 

resource "azurerm_function_app" "FunctionApp" {
  name                       = "FunctionAppTerraform"
  location                   = azurerm_resource_group.RGroup.location
  resource_group_name        = azurerm_resource_group.RGroup.name
  app_service_plan_id        = azurerm_app_service_plan.ASPfun.id
  storage_account_name       = azurerm_storage_account.SAfunction.name
  storage_account_access_key = azurerm_storage_account.SAfunction.primary_access_key
app_settings = {
    "APPINSIGHTS_INSTRUMENTATIONKEY" = azurerm_application_insights.AppInsightFunctionApp.instrumentation_key
  }
}
resource "azurerm_notification_hub_namespace" "namespace" {
  name                = "NHUB-Terraform"
  resource_group_name = azurerm_resource_group.RGroup.name
  location            = azurerm_resource_group.RGroup.location
  namespace_type      = "NotificationHub"

 

  sku_name = "Free"
}
 resource "azurerm_notification_hub" "NHubs" {
  name                = "Hub-Terraform"
  namespace_name      = azurerm_notification_hub_namespace.namespace.name
  resource_group_name = azurerm_resource_group.RGroup.name
  location            = azurerm_resource_group.RGroup.location

 

   gcm_credential {
       api_key  =   "AAAA9aWAC7M:APA91bGsO-6XQwI_66gFsTCgzgG6GFClKDcuww8mvaTIgulbhRr4Zk6O6Lrg13g-YTbrwc51LdjlbZ15hKkBtySDzXWyi9GCGd16MdMC4uWNjfq1YqqyU8Tz8zlad-ko93uq5Fj5Eb3X"
   }
   apns_credential {
       application_mode = "Sandbox"
       bundle_id        = "com.xavor.smartfan"
       key_id           = "B73BJWM4R7"
       team_id          = "7SJ6HU4TP9"
       token            = "MIGTAgEAMBMGByqGSM49AgEGCCqGSM49AwEHBHkwdwIBAQQg9YYxq/um6aiqnN0+m3BvEKQURfNtfdJi3yAju8W3T3WgCgYIKoZIzj0DAQehRANCAAQFFlnrVdMoJBtBNdfDJNqZOOzWMaUQvcAdTAACMn70TN/nX28rFl6PYho6ovl1J9REHlKbLMrOAg7R/b3YsLR2"

 

   }

 

}
