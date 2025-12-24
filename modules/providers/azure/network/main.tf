locals {
  prefix                       = replace(trimspace(lower(var.prefix)), "_", "-")
  workspace                    = replace(trimspace(lower(terraform.workspace)), "-", "")
  suffix                       = var.randomization_level > 0 ? "-${random_string.workspace_scope.result}" : ""
  base_name                    = length(local.prefix) > 0 ? "${local.prefix}-${local.workspace}${local.suffix}" : "${local.workspace}${local.suffix}"
  base_name_21                 = length(local.base_name) < 22 ? local.base_name : "${substr(local.base_name, 0, 21 - length(local.suffix))}${local.suffix}"
  base_name_46                 = length(local.base_name) < 47 ? local.base_name : "${substr(local.base_name, 0, 46 - length(local.suffix))}${local.suffix}"
  base_name_60                 = length(local.base_name) < 61 ? local.base_name : "${substr(local.base_name, 0, 60 - length(local.suffix))}${local.suffix}"
  base_name_76                 = length(local.base_name) < 77 ? local.base_name : "${substr(local.base_name, 0, 76 - length(local.suffix))}${local.suffix}"
  base_name_83                 = length(local.base_name) < 84 ? local.base_name : "${substr(local.base_name, 0, 83 - length(local.suffix))}${local.suffix}"
  public_subnets               = var.create_public_subnets ? length(var.address_subnets_public) > 0 ? var.address_subnets_public : [for netnum in range(0, var.num_public_subnets) : cidrsubnet(var.address_space, 8, netnum)] : []
  private_subnets              = var.create_private_subnets ? length(var.address_subnets_private) > 0 ? var.address_subnets_private : [for netnum in range(var.num_private_subnets, var.num_private_subnets * 2) : cidrsubnet(var.address_space, 4, netnum)] : []
  database_subnets             = var.create_database_subnets ? length(var.address_subnets_database) > 0 ? var.address_subnets_database : [for netnum in range(var.num_database_subnets * 2, var.num_database_subnets * 3) : cidrsubnet(var.address_space, 8, netnum)] : []
  route_prefixes_public        = var.create_public_subnets ? length(var.route_prefixes_public) > 0 ? var.route_prefixes_public : [var.address_space, "0.0.0.0/0"] : []
  route_names_public           = var.create_public_subnets ? length(var.route_names_public) > 0 ? var.route_names_public : ["Vnet", "Internet"] : []
  route_nexthop_types_public   = var.create_public_subnets ? length(var.route_nexthop_types_public) > 0 ? var.route_nexthop_types_public : ["VnetLocal", "Internet"] : []
  route_prefixes_private       = var.create_private_subnets ? length(var.route_prefixes_private) > 0 ? var.route_prefixes_private : [var.address_space] : []
  route_names_private          = var.create_private_subnets ? length(var.route_names_private) > 0 ? var.route_names_private : ["Vnet"] : []
  route_nexthop_types_private  = var.create_private_subnets ? length(var.route_nexthop_types_private) > 0 ? var.route_nexthop_types_private : ["VnetLocal"] : []
  route_prefixes_database      = var.create_database_subnets ? length(var.route_prefixes_database) > 0 ? var.route_prefixes_database : [var.address_space] : []
  route_names_database         = var.create_database_subnets ? length(var.route_names_database) > 0 ? var.route_names_database : ["Vnet"] : []
  route_nexthop_types_database = var.create_database_subnets ? length(var.route_nexthop_types_database) > 0 ? var.route_nexthop_types_database : ["VnetLocal"] : []
  subnet_names_public          = var.create_public_subnets ? length(var.subnet_names_public) > 0 ? (var.subnet_names_public) : [for index, public_subnet in local.public_subnets : format("%s-%s-pubsub-%d", var.prefix, var.env, index + 1)] : []
  subnet_names_private         = var.create_private_subnets ? length(var.subnet_names_private) > 0 ? (var.subnet_names_private) : [for index, private_subnet in local.private_subnets : format("%s-%s-prtsub-%d", var.prefix, var.env, index + 1)] : []
  subnet_names_database        = var.create_database_subnets ? length(var.subnet_names_database) > 0 ? (var.subnet_names_database) : [for index, database_subnet in local.database_subnets : format("%s-%s-dtasub-%d", var.prefix, var.env, index + 1)] : []
  #custom_rules = var.create_network_security_group ? length(var.custom_nsg_rules) > 0 ? (var.custom_nsg_rules) : [
  custom_rules = [
    {
      name                         = format("%s-%s-%s", var.prefix, var.env, "network-sg-rule-inbound")
      priority                     = 1000
      direction                    = "Inbound"
      access                       = "Allow"
      protocol                     = "*"
      source_port_range            = "*"
      destination_port_range       = "80,443"
      destination_address_prefixes = local.public_subnets
      source_address_prefix        = "*"
    },
    {
      name                         = format("%s-%s-%s", var.prefix, var.env, "network-apim-management-inbound")
      priority                     = 1100
      direction                    = "Inbound"
      access                       = "Allow"
      protocol                     = "Tcp"
      source_port_range            = "*"
      destination_port_range       = "3443"
      #destination_address_prefixes = local.public_subnets
      source_address_prefix        = "ApiManagement"
      destination_address_prefix   = "VirtualNetwork"
    },
    {
      name                         = format("%s-%s-%s", var.prefix, var.env, "network-apim-management-lb")
      priority                     = 1200
      direction                    = "Inbound"
      access                       = "Allow"
      protocol                     = "Tcp"
      source_port_range            = "*"
      destination_port_range       = "6390"
      #destination_address_prefixes = local.public_subnets
      source_address_prefix        = "AzureLoadBalancer"
      destination_address_prefix   = "VirtualNetwork"
    }
    ] 
}

#-------------------------------
# Common Resources
#-------------------------------
data "azurerm_client_config" "current" {}
resource "random_uuid" "oauth2_permission_scopes_id" {}
resource "random_string" "workspace_scope" {
  keepers = {
    ws_name = replace(trimspace(lower(terraform.workspace)), "-", "")
    prefix  = replace(trimspace(lower(var.prefix)), "_", "-")
  }
  length  = max(1, var.randomization_level)
  special = false
  upper   = false
}

module "vnet" {
  count                = var.create_vnet ? 1 : 0
  source               = "./modules/vnet"
  resource_group_name  = var.resource_group_name
  use_for_each         = true
  address_space        = [var.address_space]
  vnet_name            = format("%s-%s-vnet", var.prefix, var.env)
  subnet_prefixes      = concat(local.public_subnets, local.private_subnets, local.database_subnets)
  subnet_names         = concat(local.subnet_names_public, local.subnet_names_private, local.subnet_names_database)
  vnet_location        = var.vnet_location
  ddos_protection_plan = var.ddos_protection_plan
  subnet_service_endpoints = {}
  subnets = {
    trk-mt-prod-prtsub-4 = {
      delegation = {
          name = "fapp-deligation"
          service_delegation = {
            name = "Microsoft.Web/serverFarms"
            actions = ["Microsoft.Network/virtualNetworks/subnets/action", "Microsoft.Network/virtualNetworks/subnets/join/action", "Microsoft.Network/virtualNetworks/subnets/prepareNetworkPolicies/action"]
        }
      }
    }
    trk-mt-prod-dtasub-1 = {
      delegation = {
          name = "db-deligation"
          service_delegation = {
            name = "Microsoft.Sql/managedInstances"
            actions = ["Microsoft.Network/virtualNetworks/subnets/join/action", "Microsoft.Network/virtualNetworks/subnets/prepareNetworkPolicies/action", "Microsoft.Network/virtualNetworks/subnets/unprepareNetworkPolicies/action"]
        }
      }
    }
} 
  route_tables_ids = merge(
    (var.create_public_subnets ? (length(local.subnet_names_public) > 0 ? { for subnet_name in local.subnet_names_public : subnet_name => "${module.routetable_public[0].routetable_id}" } : null) : null),
    (var.create_private_subnets ? (length(local.subnet_names_private) > 0 ? { for subnet_name in local.subnet_names_private : subnet_name => "${module.routetable_private[0].routetable_id}" } : null) : null),
    (var.create_database_subnets ? (length(local.subnet_names_database) > 0 ? { for subnet_name in local.subnet_names_database : subnet_name => "${module.routetable_database[0].routetable_id}" } : null) : null)
  )
  nsg_ids = merge(
    (var.create_public_subnets ? (length(local.subnet_names_public) > 0 ? { for subnet_name in local.subnet_names_public : subnet_name => "${module.network_security_group[0].network_security_group_id}" } : null) : null),
    (var.create_private_subnets ? (length(local.subnet_names_private) > 0 ? { for subnet_name in local.subnet_names_private : subnet_name => "${module.network_security_group[0].network_security_group_id}" } : null) : null),
    (var.create_database_subnets ? (length(local.subnet_names_database) > 0 ? { for subnet_name in local.subnet_names_database : subnet_name => "${module.network_security_group[0].network_security_group_id}" } : null) : null)
  )
  tags = var.resource_tags
}

module "routetable_public" {
  count                         = var.create_public_subnets ? 1 : 0
  source                        = "./modules/routetable"
  resource_group_name           = var.resource_group_name
  location = var.vnet_location
  resource_group_location       = var.resource_group_location
  route_prefixes                = local.route_prefixes_public
  route_nexthop_types           = local.route_nexthop_types_public
  route_names                   = local.route_names_public
  route_table_name              = format("%s-%s-pubrt", var.prefix, var.env)
  disable_bgp_route_propagation = var.disable_bgp_route_propagation_public
  tags                          = var.resource_tags
}

module "routetable_private" {
  count                         = var.create_private_subnets ? 1 : 0
  source                        = "./modules/routetable"
  resource_group_name           = var.resource_group_name
  resource_group_location       = var.resource_group_location
  location = var.vnet_location
  route_prefixes                = local.route_prefixes_private
  route_nexthop_types           = local.route_nexthop_types_private
  route_names                   = local.route_names_private
  route_table_name              = format("%s-%s-prtrt", var.prefix, var.env)
  disable_bgp_route_propagation = var.disable_bgp_route_propagation_private
  tags                          = var.resource_tags
}

module "routetable_database" {
  count                         = var.create_database_subnets ? 1 : 0
  source                        = "./modules/routetable"
  resource_group_name           = var.resource_group_name
  resource_group_location       = var.resource_group_location
  location = var.vnet_location
  route_prefixes                = local.route_prefixes_database
  route_nexthop_types           = local.route_nexthop_types_database
  route_names                   = local.route_names_database
  route_table_name              = format("%s-%s-dbrt", var.prefix, var.env)
  disable_bgp_route_propagation = var.disable_bgp_route_propagation_database
  tags                          = var.resource_tags
}

module "network_security_group" {
  count                 = var.create_network_security_group ? 1 : 0
  source                = "./modules/nsg"
  location = var.vnet_location
  resource_group_name   = var.resource_group_name
  security_group_name   = format("%s-%s-nsg", var.prefix, var.env)
  source_address_prefix = [var.address_space]
  tags                  = var.resource_tags
  custom_rules          = local.custom_rules
  
}

module "nat_gateway" {
  count                       = var.create_nat_gateway ? 1 : 0
  source                      = "./modules/nat-gateway"
  depends_on                  = [module.vnet]
  name                        = format("%s-%s-nat", var.prefix, var.env)
  subnet_ids                  = slice(module.vnet[0].vnet_subnets, 0, (length(module.vnet[0].vnet_subnets) - (length(local.public_subnets))))
  location                    = var.resource_group_location
  resource_group_name         = var.resource_group_name
  create_public_ip            = var.create_public_ip
  public_ip_zones             = var.public_ip_zones
  public_ip_ids               = var.public_ip_ids
  public_ip_domain_name_label = var.public_ip_domain_name_label
  public_ip_reverse_fqdn      = var.public_ip_reverse_fqdn
  nat_gateway_idle_timeout    = var.nat_gateway_idle_timeout
  tags                        = var.resource_tags
}
