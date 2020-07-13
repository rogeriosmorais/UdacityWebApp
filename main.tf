provider "azurerm" {
  version = "~>2.0"
  tenant_id       =  ""
  subscription_id =  ""
  client_id       = ""
  client_secret   = ""
  features {}
}

resource "azurerm_resource_group" "resourcegroup" {
  tags     = var.tags
  name     = var.resourcegroup_name
  location = var.location  
}

resource "azurerm_virtual_network" "network" {  
  resource_group_name = azurerm_resource_group.resourcegroup.name  
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.resourcegroup.location
  tags                = var.tags
  name                = "${var.prefix}-VirtualNetwork"
}

resource "azurerm_subnet" "subnet_id"{
  virtual_network_name= azurerm_virtual_network.network.name  
  resource_group_name = azurerm_resource_group.resourcegroup.name  
  address_prefixes     = ["10.0.1.0/24"]
  name                = "${var.prefix}-subnet"
}

resource "azurerm_network_security_group" "NetworkSecurityGroup" {
  name                = "${var.prefix}-securitygroup"
  location            = azurerm_resource_group.resourcegroup.location
  resource_group_name = azurerm_resource_group.resourcegroup.name

  security_rule {
    name                       = "VirtualOutboundAllow"
    priority                   = 100
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "*"
  }
  security_rule {
    name                       = "VirtualInboundAllow"
    priority                   = 101
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "Internet"
    destination_address_prefix = "*"
  }
  security_rule {
    name                       = "HTTPAllow"
    priority                   = 102
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "TCP"
    source_port_range          = "*"
    destination_port_range     = "8080"
    source_address_prefix      = "Internet"
    destination_address_prefix = "*"
  }
  security_rule {
    name                       = "SSHAllow"
    priority                   = 103
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }  
  security_rule {
    name                       = "InternetInboundDeny"
    priority                   = 200
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "Internet"
    destination_address_prefix = "*"
  }
  security_rule {
    name                       = "InternetOutboundDeny"
    priority                   = 201
    direction                  = "Outbound"
    access                     = "Deny"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
  tags                         =  var.tags
}

resource "azurerm_public_ip" "api" {
  name                = "${var.prefix}-publicIP"
  location            = azurerm_resource_group.resourcegroup.location
  resource_group_name = azurerm_resource_group.resourcegroup.name
  allocation_method   = "Dynamic"
  tags                = var.tags
}



resource "azurerm_network_interface" "network_interface" {
  count               = var.vm_count
  name                = "${var.prefix}NetworkInterface-nic${count.index}"

  location            = azurerm_resource_group.resourcegroup.location
  resource_group_name = azurerm_resource_group.resourcegroup.name

  ip_configuration {
    name                          = "Configuration"
    subnet_id                     = azurerm_subnet.subnet_id.id
    private_ip_address_allocation = "Dynamic"    
  }
  tags                         =  var.tags
}


resource "azurerm_network_interface_security_group_association" "NetworkInterfaceSGAssoc" {
  count = var.vm_count
  network_interface_id     =  azurerm_network_interface.network_interface[count.index].id
  network_security_group_id = azurerm_network_security_group.NetworkSecurityGroup.id
}

resource "azurerm_public_ip" "LoadBalancerIP" {
  name                = "${var.prefix}-PublicIPForLB"
  location            = azurerm_resource_group.resourcegroup.location
  resource_group_name = azurerm_resource_group.resourcegroup.name
  allocation_method   = "Dynamic"
  tags                = var.tags
}

resource "azurerm_lb" "LoadBalancer" {
  name                = "${var.prefix}-LoadBalancer"
  location            = azurerm_resource_group.resourcegroup.location
  resource_group_name = azurerm_resource_group.resourcegroup.name

  frontend_ip_configuration {
    name                 = "PublicIPAddress"
    public_ip_address_id = azurerm_public_ip.LoadBalancerIP.id
  }
  tags                = var.tags
}

resource "azurerm_lb_backend_address_pool" "alb_backend" {
  resource_group_name = azurerm_resource_group.resourcegroup.name
  loadbalancer_id     = azurerm_lb.LoadBalancer.id
  name                = "BackEndAddressPool"
}

resource "azurerm_lb_nat_rule" "natRule" {
  resource_group_name            = azurerm_resource_group.resourcegroup.name
  loadbalancer_id                = azurerm_lb.LoadBalancer.id
  name                           = "HTTPSAccess"
  protocol                       = "Tcp"
  frontend_port                  = 338
  backend_port                   = 338
  frontend_ip_configuration_name = azurerm_lb.LoadBalancer.frontend_ip_configuration[0].name
}

resource "azurerm_network_interface_backend_address_pool_association" "NetworkInterfaceBackend" {  
  count = var.vm_count
  backend_address_pool_id = azurerm_lb_backend_address_pool.alb_backend.id
  ip_configuration_name   = "Configuration"
  network_interface_id    = element(azurerm_network_interface.network_interface.*.id, count.index)  
 
}

resource "azurerm_availability_set" "set" {
  name                = "${var.prefix}Availability_set"
  location            =  azurerm_resource_group.resourcegroup.location
  resource_group_name =  azurerm_resource_group.resourcegroup.name
  managed             =  true
  platform_fault_domain_count  = 2
  platform_update_domain_count = 2
  tags                =  var.tags
}

data "azurerm_resource_group" "image" {
  name = var.resourcegroup_name
}

data "azurerm_image" "image" {
  name                = "UdacityWebServerImage"
  resource_group_name = data.azurerm_resource_group.image.name
}

resource "azurerm_linux_virtual_machine" "virtualmachine" {  
  count               = var.vm_count
  name                = "${var.prefix}-Machine${count.index}"
  resource_group_name = azurerm_resource_group.resourcegroup.name
  location            = azurerm_resource_group.resourcegroup.location
  size                = "Standard_F2"
  admin_username      = "adminuser"
  availability_set_id   = azurerm_availability_set.set.id  
  network_interface_ids = [
    azurerm_network_interface.network_interface[count.index].id
  ]

  admin_ssh_key {
    username   = "adminuser"
    public_key = file("~/key.pub")
   
  }

  source_image_id = data.azurerm_image.image.id

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  tags = var.tags
}

resource "azurerm_managed_disk" "data" {
  count                           = var.vm_count
  name                            = "${var.prefix}-md${count.index}"
  resource_group_name             = azurerm_resource_group.resourcegroup.name
  location                        = azurerm_resource_group.resourcegroup.location
  create_option                   = "Empty"
  disk_size_gb                    = 10
  storage_account_type            = "Standard_LRS"
  tags = var.tags
}

resource "azurerm_virtual_machine_data_disk_attachment" "data" {
  count              = var.vm_count
  virtual_machine_id = azurerm_linux_virtual_machine.virtualmachine[count.index].id
  managed_disk_id    = azurerm_managed_disk.data[count.index].id
  lun                = 0
  caching            = "None"
}