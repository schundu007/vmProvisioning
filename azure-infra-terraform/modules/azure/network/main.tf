#===============================================================================
# Azure Network Module
# Creates: VNet, Subnets, NSG, Route Tables, NAT Gateway
#===============================================================================

locals {
  base_name = "${var.prefix}-${var.environment}"
  
  # Calculate subnet CIDRs if not provided
  public_subnets = var.create_public_subnets ? (
    length(var.public_subnet_cidrs) > 0 ? var.public_subnet_cidrs : [
      for i in range(var.num_public_subnets) : cidrsubnet(var.address_space, 8, i)
    ]
  ) : []
  
  private_subnets = var.create_private_subnets ? (
    length(var.private_subnet_cidrs) > 0 ? var.private_subnet_cidrs : [
      for i in range(var.num_private_subnets) : cidrsubnet(var.address_space, 8, i + 10)
    ]
  ) : []
  
  database_subnets = var.create_database_subnets ? (
    length(var.database_subnet_cidrs) > 0 ? var.database_subnet_cidrs : [
      for i in range(var.num_database_subnets) : cidrsubnet(var.address_space, 8, i + 20)
    ]
  ) : []

  # Subnet names
  public_subnet_names = [
    for i in range(length(local.public_subnets)) : "${local.base_name}-public-${i + 1}"
  ]
  
  private_subnet_names = [
    for i in range(length(local.private_subnets)) : "${local.base_name}-private-${i + 1}"
  ]
  
  database_subnet_names = [
    for i in range(length(local.database_subnets)) : "${local.base_name}-database-${i + 1}"
  ]

  # All subnets combined
  all_subnet_cidrs = concat(local.public_subnets, local.private_subnets, local.database_subnets)
  all_subnet_names = concat(local.public_subnet_names, local.private_subnet_names, local.database_subnet_names)
}

#-------------------------------------------------------------------------------
# Virtual Network
#-------------------------------------------------------------------------------
resource "azurerm_virtual_network" "main" {
  name                = "${local.base_name}-vnet"
  location            = var.location
  resource_group_name = var.resource_group_name
  address_space       = [var.address_space]
  
  tags = var.tags
}

#-------------------------------------------------------------------------------
# Subnets
#-------------------------------------------------------------------------------
resource "azurerm_subnet" "public" {
  count                = length(local.public_subnets)
  name                 = local.public_subnet_names[count.index]
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = [local.public_subnets[count.index]]
}

resource "azurerm_subnet" "private" {
  count                = length(local.private_subnets)
  name                 = local.private_subnet_names[count.index]
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = [local.private_subnets[count.index]]
}

resource "azurerm_subnet" "database" {
  count                = length(local.database_subnets)
  name                 = local.database_subnet_names[count.index]
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = [local.database_subnets[count.index]]

  delegation {
    name = "database-delegation"
    service_delegation {
      name = "Microsoft.Sql/managedInstances"
      actions = [
        "Microsoft.Network/virtualNetworks/subnets/join/action",
        "Microsoft.Network/virtualNetworks/subnets/prepareNetworkPolicies/action",
        "Microsoft.Network/virtualNetworks/subnets/unprepareNetworkPolicies/action"
      ]
    }
  }
}

#-------------------------------------------------------------------------------
# Network Security Group
#-------------------------------------------------------------------------------
resource "azurerm_network_security_group" "main" {
  name                = "${local.base_name}-nsg"
  location            = var.location
  resource_group_name = var.resource_group_name
  
  tags = var.tags
}

# Default NSG Rules
resource "azurerm_network_security_rule" "allow_https_inbound" {
  name                        = "AllowHTTPSInbound"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "443"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = var.resource_group_name
  network_security_group_name = azurerm_network_security_group.main.name
}

resource "azurerm_network_security_rule" "allow_http_inbound" {
  name                        = "AllowHTTPInbound"
  priority                    = 110
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "80"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = var.resource_group_name
  network_security_group_name = azurerm_network_security_group.main.name
}

# Custom NSG Rules
resource "azurerm_network_security_rule" "custom" {
  for_each = { for rule in var.custom_nsg_rules : rule.name => rule }

  name                        = each.value.name
  priority                    = each.value.priority
  direction                   = each.value.direction
  access                      = each.value.access
  protocol                    = each.value.protocol
  source_port_range           = each.value.source_port_range
  destination_port_range      = each.value.destination_port_range
  source_address_prefix       = each.value.source_address_prefix
  destination_address_prefix  = each.value.destination_address_prefix
  resource_group_name         = var.resource_group_name
  network_security_group_name = azurerm_network_security_group.main.name
}

#-------------------------------------------------------------------------------
# NSG Associations
#-------------------------------------------------------------------------------
resource "azurerm_subnet_network_security_group_association" "public" {
  count                     = length(azurerm_subnet.public)
  subnet_id                 = azurerm_subnet.public[count.index].id
  network_security_group_id = azurerm_network_security_group.main.id
}

resource "azurerm_subnet_network_security_group_association" "private" {
  count                     = length(azurerm_subnet.private)
  subnet_id                 = azurerm_subnet.private[count.index].id
  network_security_group_id = azurerm_network_security_group.main.id
}

#-------------------------------------------------------------------------------
# Route Tables
#-------------------------------------------------------------------------------
resource "azurerm_route_table" "public" {
  count                         = var.create_public_subnets ? 1 : 0
  name                          = "${local.base_name}-public-rt"
  location                      = var.location
  resource_group_name           = var.resource_group_name
  disable_bgp_route_propagation = false

  route {
    name                   = "Internet"
    address_prefix         = "0.0.0.0/0"
    next_hop_type          = "Internet"
  }

  tags = var.tags
}

resource "azurerm_route_table" "private" {
  count                         = var.create_private_subnets ? 1 : 0
  name                          = "${local.base_name}-private-rt"
  location                      = var.location
  resource_group_name           = var.resource_group_name
  disable_bgp_route_propagation = true

  tags = var.tags
}

#-------------------------------------------------------------------------------
# Route Table Associations
#-------------------------------------------------------------------------------
resource "azurerm_subnet_route_table_association" "public" {
  count          = length(azurerm_subnet.public)
  subnet_id      = azurerm_subnet.public[count.index].id
  route_table_id = azurerm_route_table.public[0].id
}

resource "azurerm_subnet_route_table_association" "private" {
  count          = length(azurerm_subnet.private)
  subnet_id      = azurerm_subnet.private[count.index].id
  route_table_id = azurerm_route_table.private[0].id
}

#-------------------------------------------------------------------------------
# NAT Gateway
#-------------------------------------------------------------------------------
resource "azurerm_public_ip" "nat" {
  count               = var.create_nat_gateway ? 1 : 0
  name                = "${local.base_name}-nat-pip"
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"
  sku                 = "Standard"
  zones               = ["1"]

  tags = var.tags
}

resource "azurerm_nat_gateway" "main" {
  count                   = var.create_nat_gateway ? 1 : 0
  name                    = "${local.base_name}-nat"
  location                = var.location
  resource_group_name     = var.resource_group_name
  sku_name                = "Standard"
  idle_timeout_in_minutes = 10

  tags = var.tags
}

resource "azurerm_nat_gateway_public_ip_association" "main" {
  count                = var.create_nat_gateway ? 1 : 0
  nat_gateway_id       = azurerm_nat_gateway.main[0].id
  public_ip_address_id = azurerm_public_ip.nat[0].id
}

resource "azurerm_subnet_nat_gateway_association" "private" {
  count          = var.create_nat_gateway ? length(azurerm_subnet.private) : 0
  subnet_id      = azurerm_subnet.private[count.index].id
  nat_gateway_id = azurerm_nat_gateway.main[0].id
}
