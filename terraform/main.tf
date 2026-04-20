terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.0"
    }
  }
  required_version = ">= 1.0"
}

provider "azurerm" {
  features {}
  subscription_id = var.subscription_id
}

# RESOURCE GROUP
resource "azurerm_resource_group" "main" {
  name     = "${var.project_name}-${var.environment}-rg"
  location = var.location

  tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

# NETWORKING
resource "azurerm_virtual_network" "main" {
  name                = "${var.project_name}-vnet"
  address_space       = [var.vnet_address_space]
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  tags = { Project = var.project_name }
}

resource "azurerm_subnet" "main" {
  name                 = "${var.project_name}-subnet"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = [var.subnet_address_prefix]
}

# NSG — APPLICATION NODE
resource "azurerm_network_security_group" "app_node" {
  name                = "${var.project_name}-app-nsg"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  security_rule {
    name                       = "Allow-SSH"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = var.allowed_ssh_ip
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Allow-App-Port"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "3001"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Allow-Node-Exporter"
    priority                   = 120
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "9100"
    source_address_prefix      = var.vnet_address_space
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Allow-App-Metrics"
    priority                   = 130
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "9091"
    source_address_prefix      = var.vnet_address_space
    destination_address_prefix = "*"
  }

  tags = { Project = var.project_name }
}

# NSG — MONITORING NODE
resource "azurerm_network_security_group" "monitoring_node" {
  name                = "${var.project_name}-monitoring-nsg"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  security_rule {
    name                       = "Allow-SSH"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = var.allowed_ssh_ip
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Allow-Grafana"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "3000"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Allow-Prometheus"
    priority                   = 120
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "9090"
    source_address_prefix      = var.vnet_address_space
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Allow-Alertmanager"
    priority                   = 130
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "9093"
    source_address_prefix      = var.vnet_address_space
    destination_address_prefix = "*"
  }

  tags = { Project = var.project_name }
}

# SSH KEY (auto-generated)
resource "tls_private_key" "ssh_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "local_file" "ssh_private_key" {
  content         = tls_private_key.ssh_key.private_key_pem
  filename        = "${path.module}/ssh-key/devops-project.pem"
  file_permission = "0600"
}

# APPLICATION NODE
resource "azurerm_public_ip" "app_node" {
  name                = "${var.project_name}-app-pip"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  allocation_method   = "Static"
  sku                 = "Standard"

  tags = { Project = var.project_name, Role = "application" }
}

resource "azurerm_network_interface" "app_node" {
  name                = "${var.project_name}-app-nic"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.main.id
    private_ip_address_allocation = "Static"
    private_ip_address            = "10.0.1.10"
    public_ip_address_id          = azurerm_public_ip.app_node.id
  }

  tags = { Project = var.project_name, Role = "application" }
}

resource "azurerm_network_interface_security_group_association" "app_node" {
  network_interface_id      = azurerm_network_interface.app_node.id
  network_security_group_id = azurerm_network_security_group.app_node.id
}

resource "azurerm_linux_virtual_machine" "app_node" {
  name                            = "${var.project_name}-app-vm"
  resource_group_name             = azurerm_resource_group.main.name
  location                        = azurerm_resource_group.main.location
  size                            = var.vm_size
  admin_username                  = var.admin_username
  disable_password_authentication = true

  network_interface_ids = [azurerm_network_interface.app_node.id]

  admin_ssh_key {
    username   = var.admin_username
    public_key = tls_private_key.ssh_key.public_key_openssh
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
    disk_size_gb         = 30
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-arm64"
    version   = "latest"
  }

  tags = {
    Project     = var.project_name
    Environment = var.environment
    Role        = "application"
    ManagedBy   = "Terraform"
  }
}

# MONITORING NODE
resource "azurerm_public_ip" "monitoring_node" {
  name                = "${var.project_name}-monitoring-pip"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  allocation_method   = "Static"
  sku                 = "Standard"

  tags = { Project = var.project_name, Role = "monitoring" }
}

resource "azurerm_network_interface" "monitoring_node" {
  name                = "${var.project_name}-monitoring-nic"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.main.id
    private_ip_address_allocation = "Static"
    private_ip_address            = "10.0.1.20"
    public_ip_address_id          = azurerm_public_ip.monitoring_node.id
  }

  tags = { Project = var.project_name, Role = "monitoring" }
}

resource "azurerm_network_interface_security_group_association" "monitoring_node" {
  network_interface_id      = azurerm_network_interface.monitoring_node.id
  network_security_group_id = azurerm_network_security_group.monitoring_node.id
}

resource "azurerm_linux_virtual_machine" "monitoring_node" {
  name                            = "${var.project_name}-monitoring-vm"
  resource_group_name             = azurerm_resource_group.main.name
  location                        = azurerm_resource_group.main.location
  size                            = var.vm_size
  admin_username                  = var.admin_username
  disable_password_authentication = true

  network_interface_ids = [azurerm_network_interface.monitoring_node.id]

  admin_ssh_key {
    username   = var.admin_username
    public_key = tls_private_key.ssh_key.public_key_openssh
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
    disk_size_gb         = 30
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-arm64"
    version   = "latest"
  }

  tags = {
    Project     = var.project_name
    Environment = var.environment
    Role        = "monitoring"
    ManagedBy   = "Terraform"
  }
}