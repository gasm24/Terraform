# Configure the Microsoft Azure Provider.
terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      version = ">= 2.26"
    }
  }
}

provider "azurerm" {
  features {}
}

# Create a resource group
resource "azurerm_resource_group" "rg" {
  name     = "rg-wwe-demop-espx"
  location = var.location
  tags     = var.tags
}


# Create virtual network
resource "azurerm_virtual_network" "vnt" {
  name                = "vnt-${lookup(var.locationcode, var.location)}-${var.customercode}-001"
  address_space       = [element(var.vnt_address_space,0)]
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  tags                = var.tags
}

# Gateway subnet
resource "azurerm_subnet" "gateway_subnet" {
  name                 = "GatewaySubnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnt.name
  address_prefixes       = [element(var.private_subnet_cidr_blocks,0)]
} 

# Virtual Machines subnet
resource "azurerm_subnet" "vm_subnet" {
  name                 = "sbn-${lookup(var.locationcode, var.location)}-${var.customercode}"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnt.name
  address_prefixes       = [element(var.private_subnet_cidr_blocks,1)]
} 
# Create public IP LINUX SERVER
resource "azurerm_public_ip" "publicip_vml" {
  name                = "pip-${lookup(var.locationcode, var.location)}-${var.customercode}-001"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Dynamic"
  tags = var.tags
}
 
# Create Network Security Group and rule
resource "azurerm_network_security_group" "nsg-vml" {
  name                = "nsg-${lookup(var.locationcode, var.location)}-${var.customercode}"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  tags = var.tags
 
  security_rule {
    name                       = "SSH"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}
 
# Create network interface LINUX SERVER
resource "azurerm_network_interface" "nic_vml" {
  name                      = "nic-vml-001"
  location                  = var.location
  resource_group_name       = azurerm_resource_group.rg.name
  tags = var.tags
 
  ip_configuration {
    name                          = "nic-vml-001-confg"
    subnet_id                     = azurerm_subnet.vm_subnet.id
    private_ip_address_allocation = "dynamic"
    public_ip_address_id          = azurerm_public_ip.publicip_vml.id
  }
}
 
# Create a Linux virtual machine
resource "azurerm_virtual_machine" "vml" {
  name                  = "vml-${lookup(var.locationcode, var.location)}-${var.customercode}"
  location              = var.location
  resource_group_name   = azurerm_resource_group.rg.name
  network_interface_ids = [azurerm_network_interface.nic_vml.id]
  vm_size               = "Standard_DS1_v2"
  tags = var.tags
 
  storage_os_disk {
    name              = "vml-OsDisk-001"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Premium_LRS"
  }
 
  storage_image_reference {
    publisher = "Canonical"
    offer     = var.linuxserver_offer
    sku       = lookup(var.sku, var.linuxserver_offer)
    version   = "latest"
  }
 
  os_profile {
    computer_name  = "vml-${lookup(var.locationcode, var.location)}-${var.customercode}"
    admin_username = var.admin_username
    admin_password = var.admin_password
  }
 
  os_profile_linux_config {
    disable_password_authentication = false
  }
}
 
data "azurerm_public_ip" "ip" {
  name                = azurerm_public_ip.publicip_vml.name
  resource_group_name = azurerm_virtual_machine.vml.resource_group_name
  depends_on          = [azurerm_virtual_machine.vml]
}


# Create public IP WINDOWS SERVER
resource "azurerm_public_ip" "publicip_vmw" {
  name                = "pip-${lookup(var.locationcode, var.location)}-${var.customercode}-002"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Dynamic"
  tags = var.tags
}

# Create network interface WINDOWS SERVER
resource "azurerm_network_interface" "nic_vmw" {
  name                      = "nic-vmw-001"
  location                  = var.location
  resource_group_name       = azurerm_resource_group.rg.name
  tags = var.tags
 
  ip_configuration {
    name                          = "nic-vmw-001-confg"
    subnet_id                     = azurerm_subnet.vm_subnet.id
    private_ip_address_allocation = "dynamic"
    public_ip_address_id          = azurerm_public_ip.publicip_vmw.id
  }
}


# Create a Windows virtual machine
resource "azurerm_virtual_machine" "vmw" {
  name                  = "vmw-${lookup(var.locationcode, var.location)}-${var.customercode}"
  location              = var.location
  resource_group_name   = azurerm_resource_group.rg.name
  network_interface_ids = [azurerm_network_interface.nic_vmw.id]
  vm_size               = "Standard_DS1_v2"
  tags = var.tags
 
  storage_os_disk {
    name              = "vmw-OsDisk-001"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Premium_LRS"
  }
 
  storage_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = var.windowsserver_offer
    sku       = lookup(var.sku, var.windowsserver_offer)
    version   = "latest"
  }
 
  os_profile {
    computer_name  = "vmw-${lookup(var.locationcode, var.location)}-${var.customercode}"
    admin_username = var.admin_username
    admin_password = var.admin_password
  }
 
  os_profile_windows_config {
    enable_automatic_upgrades = false
  }
}
 
data "azurerm_public_ip" "ip_vmw" {
  name                = azurerm_public_ip.publicip_vmw.name
  resource_group_name = azurerm_virtual_machine.vmw.resource_group_name
  depends_on          = [azurerm_virtual_machine.vmw]
}


# # Create a Virtual Network Gateway - PIP


# resource "azurerm_public_ip" "pip-vgw" {
#   name                = "pip-${lookup(var.locationcode, var.location)}-${var.customercode}-vgw"
#   location            = azurerm_resource_group.rg.location
#   resource_group_name = azurerm_resource_group.rg.name
#   tags = var.tags

#   allocation_method = "Dynamic"
# }

# # Create a Virtual Network Gateway

# resource "azurerm_virtual_network_gateway" "vgw" {
#   name                = "vgw-${lookup(var.locationcode, var.location)}-${var.customercode}-001"
#   location            = var.location
#   resource_group_name = azurerm_resource_group.rg.name
#   tags = var.tags

#   type     = "Vpn"
#   vpn_type = "RouteBased"

#   active_active = false
#   enable_bgp    = false
#   sku           = "Basic"

#   ip_configuration {
#     public_ip_address_id          = azurerm_public_ip.pip-vgw.id
#     private_ip_address_allocation = "Dynamic"
#     subnet_id                     = azurerm_subnet.gateway_subnet.id
#   }

# }


# # Create a Local Network Gateway

# resource "azurerm_local_network_gateway" "lng" {
#   name                = "lng-${lookup(var.locationcode, var.location)}-${var.customercode}-001"
#   resource_group_name = azurerm_resource_group.rg.name
#   location            = var.location
#   gateway_address     = var.lng_gateway_address
#   address_space       = [var.lng_address_space]
#   tags = var.tags
# }

# # Create Virtual Network Gateway Connection

# resource "azurerm_virtual_network_gateway_connection" "onpremise" {
#   name                = "cn-${azurerm_virtual_network_gateway.vgw.name}-to-${azurerm_local_network_gateway.lng.name}"
#   location            = var.location
#   resource_group_name = azurerm_resource_group.rg.name
#   tags = var.tags

#   type                       = "IPsec"
#   virtual_network_gateway_id = azurerm_virtual_network_gateway.vgw.id
#   local_network_gateway_id   = azurerm_local_network_gateway.lng.id

#   shared_key = var.cn_shared_key
# }
