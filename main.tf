terraform {
    required_providers {
        azurerm = {
            source  = "hashicorp/azurerm"
            version = "~> 3.0"
        }
    }
}

provider "azurerm" {
    features {}
}

resource "azurerm_resource_group" "rg" {
    name     = "rg-network-security-${var.yourname}"
    location = var.location
}

resource "azurerm_log_analytics_workspace" "law" {
    name                = "law-network-security-${var.yourname}"
    location            = azurerm_resource_group.rg.location
    resource_group_name = azurerm_resource_group.rg.name
    sku                 = "PerGB2018"
    retention_in_days   = 30
}

resource "azurerm_virtual_network" "hub" {
    name                = "vnet-hub-${var.yourname}"
    address_space       = ["10.0.0.0/16"]
    location            = azurerm_resource_group.rg.location
    resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_subnet" "firewall" {
    name = "AzureFirewallSubnet"
    resource_group_name  = azurerm_resource_group.rg.name
    virtual_network_name = azurerm_virtual_network.hub.name
    address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_virtual_network" "spoke1" {
    name                = "vnet-spoke1-${var.yourname}"
    location            = azurerm_resource_group.rg.location
    resource_group_name = azurerm_resource_group.rg.name
    address_space       = ["10.1.0.0/16"]
}

resource "azurerm_subnet" "spoke1" {
    name = "subnet-spoke1-${var.yourname}"
    resource_group_name  = azurerm_resource_group.rg.name
    virtual_network_name = azurerm_virtual_network.spoke1.name
    address_prefixes     = ["10.1.1.0/24"]
}

resource "azurerm_virtual_network" "spoke2" {
    name                = "vnet-spoke2-${var.yourname}"
    location            = azurerm_resource_group.rg.location
    resource_group_name = azurerm_resource_group.rg.name
    address_space       = ["10.2.0.0/16"]
}

resource "azurerm_subnet" "spoke2" {
    name = "subnet-spoke2-${var.yourname}"
    resource_group_name  = azurerm_resource_group.rg.name
    virtual_network_name = azurerm_virtual_network.spoke2.name
    address_prefixes     = ["10.2.1.0/24"]
}

resource "azurerm_virtual_network_peering" "hub_to_spoke1" {
    name                      = "hub-to-spoke1"
    resource_group_name       = azurerm_resource_group.rg.name
    virtual_network_name      = azurerm_virtual_network.hub.name
    remote_virtual_network_id = azurerm_virtual_network.spoke1.id
    allow_forwarded_traffic  = true
}

resource "azurerm_virtual_network_peering" "spoke1_to_hub" {
    name = "spoke1-to-hub"
    virtual_network_name      = azurerm_virtual_network.spoke1.name
    resource_group_name       = azurerm_resource_group.rg.name
    remote_virtual_network_id = azurerm_virtual_network.hub.id
    allow_forwarded_traffic  = true
}

resource "azurerm_virtual_network_peering" "hub_to_spoke2" {
    name = "hub-to-spoke2"
    resource_group_name       = azurerm_resource_group.rg.name
    virtual_network_name      = azurerm_virtual_network.hub.name
    remote_virtual_network_id = azurerm_virtual_network.spoke2.id
    allow_forwarded_traffic  = true
}

resource "azurerm_virtual_network_peering" "spoke2-to-hub" {
    name = "spoke2-to-hub"
    resource_group_name       = azurerm_resource_group.rg.name
    virtual_network_name      = azurerm_virtual_network.spoke2.name
    remote_virtual_network_id = azurerm_virtual_network.hub.id
    allow_forwarded_traffic  = true
}

resource "azurerm_public_ip" "firewall" {
    name = "pip-firewall-${var.yourname}"
    location            = azurerm_resource_group.rg.location
    resource_group_name = azurerm_resource_group.rg.name
    allocation_method   = "Static"
    sku                 = "Standard"
}

resource "azurerm_firewall" "firewall" {
    name = "fw-lab-${var.yourname}"
    location            = azurerm_resource_group.rg.location
    resource_group_name = azurerm_resource_group.rg.name
    sku_name            = "AZFW_VNet"
    sku_tier            = "Basic"
    ip_configuration {
        name = "fw-ipconfig"
        subnet_id            = azurerm_subnet.firewall.id
        public_ip_address_id = azurerm_public_ip.firewall.id
    }
}



