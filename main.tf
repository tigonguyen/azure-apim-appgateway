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
  features {}

  subscription_id = var.subscription_id
  client_id       = var.user_id
  client_secret   = var.user_secret
  tenant_id       = var.tenant_id
}

# Create resource group
resource "azurerm_resource_group" "APIM-PDL-DEV-NC" {
  name     = "APIM-PDL-DEV-NC" # resource group name
  location = var.rg_region # Azure region
}

# Create VNET and assign subnets
resource "azurerm_virtual_network" "myvnet-vnet" {
  name                = "myvnet-vnet" 
  location            = var.rg_region  # Azure region
  resource_group_name = azurerm_resource_group.APIM-PDL-DEV-NC.name # resource group name
  address_space       = [ "10.0.0.0/16" ]
}

resource "azurerm_subnet" "appgw-subnet" {
  name                 = "appgw-subnet"
  virtual_network_name = "myvnet-vnet"
  address_prefixes     = [ "10.0.0.0/24" ]
  resource_group_name  = "APIM-PDL-DEV-NC"
}

resource "azurerm_subnet" "apim-subnet" {
  name                 = "apim-subnet"
  virtual_network_name = "myvnet-vnet"
  address_prefixes     = [ "10.0.1.0/24" ]
  resource_group_name  = "APIM-PDL-DEV-NC"
}

# ------------- Deploy API Management ------------- #
resource "azurerm_api_management" "APIM-POC-ps2tf" {
  name                  = var.apimServiceName # API Management service instance name (.azure-api.net suffix will be added so has to be globally unique)
  location              = var.rg_region # Azure region
  resource_group_name   = azurerm_resource_group.APIM-PDL-DEV-NC.name # resource group name
  publisher_name        = var.apimOrganization # organization name
  publisher_email       = var.apimAdminEmail # administrator's email address
  sku_name              = "Developer_1" # value_capacity

  # Network subnet configuration
  virtual_network_type  = "Internal"
  virtual_network_configuration {
    subnet_id           = azurerm_subnet.apim-subnet.id
  }
}

# Create and set the hostname configuration objects for the proxy and portal
resource "azurerm_api_management_custom_domain" "customDomain" {
  api_management_id = azurerm_api_management.APIM-POC-ps2tf.id

  proxy {
    host_name            = var.gatewayHostname # API gateway host
    certificate          = base64encode(data.local_file.gatewayCertPfx)
    certificate_password = var.gatewayCertPfxPassword
  }

  portal {
    host_name            = var.portalHostname # API developer portal host
    certificate          = base64encode(data.local_file.portalCertPfx)
    certificate_password = var.portalCertPfxPassword
  }
}

# ------------- Deploy Application Gateway ------------- #
# Create a public IP address for the Application Gateway front-end
resource "azurerm_public_ip" "appgwapim-pip" {
  name                = "appgwapim-pip"
  resource_group_name = azurerm_resource_group.APIM-PDL-DEV-NC.name
  location            = var.rg_region
  allocation_method   = "Dynamic"
}

resource "azurerm_application_gateway" "apim-app-gw-pdl" {
  name                = var.appgwName
  resource_group_name = azurerm_resource_group.APIM-PDL-DEV-NC.name
  location            = var.rg_region

  # step 1 - create App GW IP config
  gateway_ip_configuration {
    name      = "gatewayIp"
    subnet_id = azurerm_subnet.appgw-subnet.id
  }

  # step 2 - configure the front-end IP port for the public IP endpoint
  frontend_port {
    name = "frontend-port443"
    port = 443
  }

  # step 3 - configure the front-end IP with the public IP endpoint
  frontend_ip_configuration {
    name                 = "frontend1"
    public_ip_address_id = azurerm_public_ip.appgwapim-pip.id
  }

  # step 4 - configure certs for the App Gateway
  ssl_certificate {
    name     = "apim-gw-cert01"
    data     = base64encode(data.local_file.gatewayCertPfx)
    password = var.gatewayCertPfxPassword
  }
  ssl_certificate {
    name     = "apim-portal-cert01"
    data     = base64encode(data.local_file.portalCertPfx)
    password = var.portalCertPfxPassword
  }

  # step 5 - configure HTTP listeners for the App Gateway
  http_listener {
    name                           = "apim-gw-listener01"
    protocol                       = "Https"
    frontend_ip_configuration_name = "frontend1"
    frontend_port_name             = "frontend-port443"
    ssl_certificate_name           = "apim-gw-cert01"
    host_name                      = var.gatewayHostname
    require_sni                    = true
  }
  http_listener {
    name                           = "apim-portal-listener02"
    protocol                       = "Https"
    frontend_ip_configuration_name = "frontend1"
    frontend_port_name             = "frontend-port443"
    ssl_certificate_name           = "apim-portal-cert01"
    host_name                      = var.portalHostname
    require_sni                    = true
  }

  # step 6 - create custom probes for API-M endpoints
  probe {
    name                = "apim-gw-proxyprobe"
    protocol            = "Https"
    host                = var.gatewayHostname
    path                = "/status-0123456789abcdef"
    interval            = 30
    timeout             = 120
    unhealthy_threshold = 8
  }
  probe {
    name                = "apim-portal-proxyprobe"
    protocol            = "Https"
    host                = var.portalHostname
    path                = "/signin"
    interval            = 60
    timeout             = 300
    unhealthy_threshold = 8
  }

  # step 7 - upload cert for SSL-enabled backend pool resources
  authentication_certificate {
    name = "whitelistcert1"
    data = base64encode(data.local_file.gatewayCertCer)
  }

  # step 8 - configure HTTPs backend settings for the App Gateway
  backend_http_settings {
    cookie_based_affinity = "Disabled"
    name                  = "apim-gw-poolsetting"
    protocol              = "Https"
    port                  = 443
    request_timeout       = 180
    probe_name            = "apim-gw-proxyprobe"
    authentication_certificate {
      name = "whitelistcert1"
    }
  }
  backend_http_settings {
    cookie_based_affinity = "Disabled"
    name                  = "apim-portal-poolsetting"
    protocol              = "Https"
    port                  = 443
    request_timeout       = 180
    probe_name            = "apim-portal-proxyprobe"
    authentication_certificate {
      name = "whitelistcert1"
    }
  }

  # step 9a - configure back-end IP address pool with internal IP of API-M i.e. 10.0.1.5
  backend_address_pool {
    name         = "apimbackend"
    ip_addresses = azurerm_api_management.APIM-POC-ps2tf.private_ip_addresses
  }

  # step 9b - create sinkpool for API-M requests we want to discard
  backend_address_pool {
    name = "sinkpool"
  }

  # step 10 - create a routing rule to allow external Internet access to the developer portal
  request_routing_rule {
    name                       = "apim-portal-rule01"
    rule_type                  = "Basic"
    http_listener_name         = "apim-portal-listener02"
    backend_address_pool_name  = "apimbackend"
    backend_http_settings_name = "apim-portal-poolsetting"
  }

  # step 11 - change App Gateway SKU and instances (# instances can be configured as required)
  sku {
    name     = "WAF_Medium"
    tier     = "WAF"
    capacity = 1
  }

  # step 12 - configure WAF to be in prevention mode
  waf_configuration {
    enabled          = true
    firewall_mode    = "Prevention"
    rule_set_type    = "OWASP"
    rule_set_version = "2.2.9"
  }

  # ----- Add path based routing rule for /external/* API URL's only ----- #
  url_path_map {
    name                               = "external-urlpathmapconfig"
    default_backend_address_pool_name  = "sinkpool"
    default_backend_http_settings_name = "apim-gw-poolsetting"
    path_rule {
      name                             = "external"
      paths                            = [ "/external/*" ]
      backend_address_pool_name        = "apimbackend"
      backend_http_settings_name       = "apim-gw-poolsetting"
    }
  }

  request_routing_rule {
    name                             = "apim-gw-external-rule01"
    rule_type                        = "PathBasedRouting"
    http_listener_name               = "apim-gw-listener01"
    backend_address_pool_name        = "apimbackend"
    backend_http_settings_name       = "apim-gw-poolsetting"
    url_path_map_name                = "external-urlpathmapconfig"
  }
}
