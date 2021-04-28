variable "sku" {
  default = {
    UbuntuServer = "18.04-LTS"
    WindowsServer  = "2019-Datacenter"
  }
}

variable "windowsserver_offer" {
  type = string
  default  = "WindowsServer"
}

variable "linuxserver_offer" {
  type = string
  default  = "UbuntuServer"
}

variable "locationcode" {
  default = {
    westeurope = "wwe"
  }
}

variable "location" {
  type = string
  default = "westeurope"
}


variable "customercode" {
  type = string
}

variable "admin_username" {
  type        = string
  description = "Administrator user name for virtual machine"
}

variable "admin_password" {
  type        = string
  description = "Password must meet Azure complexity requirements"
}


variable "vnt_address_space" {
  type    = list(string)
}


variable "private_subnet_cidr_blocks" {
  type        = list(string)
}


variable "tags" {
  type = map

  default = {
    created-by = "teamDevOps"
    CreationMethod ="Terraform"
  }
}


#Local Network Gateway

variable "lng_gateway_address" {
  type    = string
}

variable "lng_address_space" {
  type    = string
}

#Connection

variable "cn_shared_key" {
  type    = string
}
